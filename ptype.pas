{
    Copyright (c) 1998-2002 by Florian Klaempfl

    Does parsing types for Free Pascal

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

 ****************************************************************************
}
unit ptype;

{$i fpcdefs.inc}

interface

    uses
       globtype,cclasses,
       symtype,symdef,symbase;

    type
      TSingleTypeOption=(
        stoIsForwardDef,          { foward declaration         }
        stoAllowTypeDef,          { allow type definitions     }
        stoAllowSpecialization,   { allow type specialization  }
        stoParseClassParent       { parse of parent class type }
      );
      TSingleTypeOptions=set of TSingleTypeOption;

    procedure resolve_forward_types;

    { reads a string, file type or a type identifier }
    procedure single_type(var def:tdef;options:TSingleTypeOptions);

    { reads any type declaration, where the resulting type will get name as type identifier }
    procedure read_named_type(var def:tdef;const name : TIDString;genericdef:tstoreddef;genericlist:TFPObjectList;parseprocvardir:boolean);

    { reads any type declaration }
    procedure read_anon_type(var def : tdef;parseprocvardir:boolean);

    { generate persistent type information like VMT, RTTI and inittables }
    procedure write_persistent_type_info(st:tsymtable);

implementation

    uses
       { common }
       cutils,
       { global }
       globals,tokens,verbose,constexp,
       systems,
       { target }
       paramgr,procinfo,
       { symtable }
       symconst,symsym,symtable,
       defutil,defcmp,
       { modules }
       fmodule,
       { pass 1 }
       node,ncgrtti,nobj,
       nmat,nadd,ncal,nset,ncnv,ninl,ncon,nld,nflw,
       { parser }
       scanner,
       pbase,pexpr,pdecsub,pdecvar,pdecobj,pdecl,pgenutil,pnameless;


    procedure resolve_forward_types;
      var
        i: longint;
        hpd,
        def : tdef;
        srsym  : tsym;
        srsymtable : TSymtable;
        hs : string;
      begin
        for i:=0 to current_module.checkforwarddefs.Count-1 do
          begin
            def:=tdef(current_module.checkforwarddefs[i]);
            case def.typ of
              pointerdef,
              classrefdef :
                begin
                  { classrefdef inherits from pointerdef }
                  hpd:=tabstractpointerdef(def).pointeddef;
                  { still a forward def ? }
                  if hpd.typ=forwarddef then
                   begin
                     { try to resolve the forward }
                     if not assigned(tforwarddef(hpd).tosymname) then
                       internalerror(200211201);
                     hs:=tforwarddef(hpd).tosymname^;
                     searchsym(upper(hs),srsym,srsymtable);
                     { we don't need the forwarddef anymore, dispose it }
                     hpd.free;
                     tabstractpointerdef(def).pointeddef:=nil; { if error occurs }
                     { was a type sym found ? }
                     if assigned(srsym) and
                        (srsym.typ=typesym) then
                      begin
                        tabstractpointerdef(def).pointeddef:=ttypesym(srsym).typedef;
                        { avoid wrong unused warnings web bug 801 PM }
                        inc(ttypesym(srsym).refs);
                        { we need a class type for classrefdef }
                        if (def.typ=classrefdef) and
                           not(is_class(ttypesym(srsym).typedef)) and
                           not(is_objcclass(ttypesym(srsym).typedef)) then
                          MessagePos1(def.typesym.fileinfo,type_e_class_type_expected,ttypesym(srsym).typedef.typename);
                      end
                     else
                      begin
                        Message1(sym_e_forward_type_not_resolved,hs);
                        { try to recover }
                        tabstractpointerdef(def).pointeddef:=generrordef;
                      end;
                   end;
                end;
              objectdef :
                begin
                  { give an error as the implementation may follow in an
                    other type block which is allowed by FPC modes }
                  if not(m_fpc in current_settings.modeswitches) and
                     (oo_is_forward in tobjectdef(def).objectoptions) then
                    MessagePos1(def.typesym.fileinfo,type_e_type_is_not_completly_defined,def.typename);
                 end;
              else
                internalerror(200811071);
            end;
          end;
        current_module.checkforwarddefs.clear;
      end;


    procedure id_type(var def : tdef;isforwarddef,checkcurrentrecdef,allowgenericsyms:boolean;out srsym:tsym;out srsymtable:tsymtable); forward;


    { def is the outermost type in which other types have to be searched

      isforward indicates whether the current definition can be a forward definition

      if assigned, currentstructstack is a list of tabstractrecorddefs that, from
      last to first, are child types of def that are not yet visible via the
      normal symtable searching routines because they are types that are currently
      being parsed (so using id_type on them after pushing def on the
      symtablestack would result in errors because they'd come back as errordef)
    }
    procedure parse_nested_types(var def: tdef; isforwarddef: boolean; currentstructstack: tfpobjectlist);
      var
        t2: tdef;
        structstackindex: longint;
        srsym: tsym;
        srsymtable: tsymtable;
      begin
        if assigned(currentstructstack) then
          structstackindex:=currentstructstack.count-1
        else
          structstackindex:=-1;
        { handle types inside classes, e.g. TNode.TLongint }
        while (token=_POINT) do
          begin
             if is_class_or_object(def) or is_record(def) then
               begin
                 consume(_POINT);
                 if (structstackindex>=0) and
                    (tabstractrecorddef(currentstructstack[structstackindex]).objname^=pattern) then
                   begin
                     def:=tdef(currentstructstack[structstackindex]);
                     dec(structstackindex);
                     consume(_ID);
                   end
                 else
                   begin
                     structstackindex:=-1;
                     symtablestack.push(tabstractrecorddef(def).symtable);
                     t2:=generrordef;
                     id_type(t2,isforwarddef,false,false,srsym,srsymtable);
                     symtablestack.pop(tabstractrecorddef(def).symtable);
                     def:=t2;
                   end;
               end
             else
               break;
          end;
      end;


    function try_parse_structdef_nested_type(out def: tdef; basedef: tabstractrecorddef; isfowarddef: boolean): boolean;
      var
        structdef : tdef;
        structdefstack : tfpobjectlist;
      begin
         def:=nil;
         { use of current parsed object:
           classes, objects, records can be used also in themself }
         structdef:=basedef;
         structdefstack:=nil;
         while assigned(structdef) and (structdef.typ in [objectdef,recorddef]) do
           begin
             if (tabstractrecorddef(structdef).objname^=pattern) then
               begin
                 consume(_ID);
                 def:=structdef;
                 { we found the top-most match, now check how far down we can
                   follow }
                 structdefstack:=tfpobjectlist.create(false);
                 structdef:=basedef;
                 while (structdef<>def) do
                   begin
                     structdefstack.add(structdef);
                     structdef:=tabstractrecorddef(structdef.owner.defowner);
                   end;
                 parse_nested_types(def,isfowarddef,structdefstack);
                 structdefstack.free;
                 result:=true;
                 exit;
               end;
             structdef:=tdef(tabstractrecorddef(structdef).owner.defowner);
           end;
         result:=false;
      end;

    procedure id_type(var def : tdef;isforwarddef,checkcurrentrecdef,allowgenericsyms:boolean;out srsym:tsym;out srsymtable:tsymtable);
    { reads a type definition }
    { to a appropriating tdef, s gets the name of   }
    { the type to allow name mangling          }
      var
        is_unit_specific : boolean;
        pos : tfileposinfo;
        s,sorg : TIDString;
        t : ttoken;
      begin
         srsym:=nil;
         srsymtable:=nil;
         s:=pattern;
         sorg:=orgpattern;
         pos:=current_tokenpos;
         { use of current parsed object:
           classes, objects, records can be used also in themself }
         if checkcurrentrecdef and
            try_parse_structdef_nested_type(def,current_structdef,isforwarddef) then
           exit;
         { Use the special searchsym_type that search only types }
         searchsym_type(s,srsym,srsymtable);
         { handle unit specification like System.Writeln }
         is_unit_specific:=try_consume_unitsym(srsym,srsymtable,t,true);
         consume(t);
         { Types are first defined with an error def before assigning
           the real type so check if it's an errordef. if so then
           give an error. Only check for typesyms in the current symbol
           table as forwarddef are not resolved directly }
         if assigned(srsym) and
            (srsym.typ=typesym) and
            ((ttypesym(srsym).typedef.typ=errordef) or
            (not allowgenericsyms and
            (ttypesym(srsym).typedef.typ=undefineddef) and
            not (sp_generic_para in srsym.symoptions))) then
          begin
            Message1(type_e_type_is_not_completly_defined,ttypesym(srsym).realname);
            def:=generrordef;
            exit;
          end;
         { are we parsing a possible forward def ? }
         if isforwarddef and
            not(is_unit_specific) then
           begin
             def:=tforwarddef.create(sorg,pos);
             exit;
           end;
         { unknown sym ? }
         if not assigned(srsym) then
          begin
            Message1(sym_e_id_not_found,sorg);
            def:=generrordef;
            exit;
          end;
         { type sym ? }
         if (srsym.typ<>typesym) then
          begin
            Message(type_e_type_id_expected);
            def:=generrordef;
            exit;
          end;
         { Give an error when referring to an errordef }
         if (ttypesym(srsym).typedef.typ=errordef) then
          begin
            Message(sym_e_error_in_type_def);
            def:=generrordef;
            exit;
          end;
        def:=ttypesym(srsym).typedef;
      end;


    procedure single_type(var def:tdef;options:TSingleTypeOptions);
       var
         t2 : tdef;
         dospecialize,
         again : boolean;
         srsym : tsym;
         srsymtable : tsymtable;
       begin
         dospecialize:=false;
         repeat
           again:=false;
             case token of
               _STRING:
                 string_dec(def,stoAllowTypeDef in options);

               _FILE:
                 begin
                    consume(_FILE);
                    if (token=_OF) then
                      begin
                         if not(stoAllowTypeDef in options) then
                           Message(parser_e_no_local_para_def);
                         consume(_OF);
                         single_type(t2,[stoAllowTypeDef]);
                         if is_managed_type(t2) then
                           Message(parser_e_no_refcounted_typed_file);
                         def:=tfiledef.createtyped(t2);
                      end
                    else
                      def:=cfiletype;
                 end;

               _ID:
                 begin
                   if try_to_consume(_SPECIALIZE) then
                     begin
                       if ([stoAllowSpecialization,stoAllowTypeDef] * options = []) then
                         begin
                           Message(parser_e_no_local_para_def);

                           { try to recover }
                           while token<>_SEMICOLON do
                             consume(token);
                           def:=generrordef;
                         end
                       else
                         begin
                           dospecialize:=true;
                           again:=true;
                         end;
                     end
                   else
                     begin
                       id_type(def,stoIsForwardDef in options,true,true,srsym,srsymtable);
                       parse_nested_types(def,stoIsForwardDef in options,nil);
                     end;
                 end;

               else
                 begin
                   message(type_e_type_id_expected);
                   def:=generrordef;
                 end;
            end;
        until not again;
        if ([stoAllowSpecialization,stoAllowTypeDef] * options <> []) and
           (m_delphi in current_settings.modeswitches) then
          dospecialize:=token in [_LSHARPBRACKET,_LT];
        if dospecialize then
          generate_specialization(def,stoParseClassParent in options,'',nil,'')
        else
          begin
            if assigned(current_specializedef) and (def=current_specializedef.genericdef) then
              begin
                def:=current_specializedef
              end
            else if (def=current_genericdef) then
              begin
                def:=current_genericdef
              end
            else if (df_generic in def.defoptions) and
                not
                  (
                    parse_generic and
                    (current_genericdef.typ in [recorddef,objectdef]) and
                    sym_is_owned_by(srsym,tabstractrecorddef(current_genericdef).symtable)
                  )
                then
              begin
                Message(parser_e_no_generics_as_types);
                def:=generrordef;
              end
            else if is_classhelper(def) and
                not (stoParseClassParent in options) then
              begin
                Message(parser_e_no_category_as_types);
                def:=generrordef
              end
          end;
      end;

    procedure parse_record_members;

        procedure maybe_parse_hint_directives(pd:tprocdef);
        var
          dummysymoptions : tsymoptions;
          deprecatedmsg : pshortstring;
        begin
          dummysymoptions:=[];
          deprecatedmsg:=nil;
          while try_consume_hintdirective(dummysymoptions,deprecatedmsg) do
            Consume(_SEMICOLON);
          if assigned(pd) then
            begin
              pd.symoptions:=pd.symoptions+dummysymoptions;
              pd.deprecatedmsg:=deprecatedmsg;
            end
          else
            stringdispose(deprecatedmsg);
        end;

      var
        pd : tprocdef;
        oldparse_only: boolean;
        member_blocktype : tblock_type;
        fields_allowed, is_classdef, classfields: boolean;
        vdoptions: tvar_dec_options;
      begin
        { empty record declaration ? }
        if (token=_SEMICOLON) then
          Exit;

        current_structdef.symtable.currentvisibility:=vis_public;
        fields_allowed:=true;
        is_classdef:=false;
        classfields:=false;
        member_blocktype:=bt_general;
        repeat
          case token of
            _TYPE :
              begin
                consume(_TYPE);
                member_blocktype:=bt_type;

                { local and anonymous records can not have inner types. skip top record symtable }
                if (current_structdef.objname^='') or
                   not(symtablestack.stack^.next^.symtable.symtabletype in [globalsymtable,staticsymtable,objectsymtable,recordsymtable]) then
                  Message(parser_e_no_types_in_local_anonymous_records);
              end;
            _VAR :
              begin
                consume(_VAR);
                fields_allowed:=true;
                member_blocktype:=bt_general;
                classfields:=is_classdef;
                is_classdef:=false;
              end;
            _CONST:
              begin
                consume(_CONST);
                member_blocktype:=bt_const;
              end;
            _ID, _CASE, _OPERATOR :
              begin
                case idtoken of
                  _PRIVATE :
                    begin
                       consume(_PRIVATE);
                       current_structdef.symtable.currentvisibility:=vis_private;
                       include(current_structdef.objectoptions,oo_has_private);
                       fields_allowed:=true;
                       is_classdef:=false;
                       classfields:=false;
                       member_blocktype:=bt_general;
                     end;
                   _PROTECTED :
                     begin
                       consume(_PROTECTED);
                       current_structdef.symtable.currentvisibility:=vis_protected;
                       include(current_structdef.objectoptions,oo_has_protected);
                       fields_allowed:=true;
                       is_classdef:=false;
                       classfields:=false;
                       member_blocktype:=bt_general;
                     end;
                   _PUBLIC :
                     begin
                       consume(_PUBLIC);
                       current_structdef.symtable.currentvisibility:=vis_public;
                       fields_allowed:=true;
                       is_classdef:=false;
                       classfields:=false;
                       member_blocktype:=bt_general;
                     end;
                   _PUBLISHED :
                     begin
                       Message(parser_e_no_record_published);
                       consume(_PUBLISHED);
                       current_structdef.symtable.currentvisibility:=vis_published;
                       fields_allowed:=true;
                       is_classdef:=false;
                       classfields:=false;
                       member_blocktype:=bt_general;
                     end;
                   _STRICT :
                     begin
                        consume(_STRICT);
                        if token=_ID then
                          begin
                            case idtoken of
                              _PRIVATE:
                                begin
                                  consume(_PRIVATE);
                                  current_structdef.symtable.currentvisibility:=vis_strictprivate;
                                  include(current_structdef.objectoptions,oo_has_strictprivate);
                                end;
                              _PROTECTED:
                                begin
                                  consume(_PROTECTED);
                                  current_structdef.symtable.currentvisibility:=vis_strictprotected;
                                  include(current_structdef.objectoptions,oo_has_strictprotected);
                                end;
                              else
                                message(parser_e_protected_or_private_expected);
                            end;
                          end
                        else
                          message(parser_e_protected_or_private_expected);
                        fields_allowed:=true;
                        is_classdef:=false;
                        classfields:=false;
                        member_blocktype:=bt_general;
                     end
                    else
                    if is_classdef and (idtoken=_OPERATOR) then
                      begin
                        oldparse_only:=parse_only;
                        parse_only:=true;
                        pd:=parse_proc_dec(current_structdef,ppm_class_method);

                        { this is for error recovery as well as forward }
                        { interface mappings, i.e. mapping to a method  }
                        { which isn't declared yet                      }
                        if assigned(pd) then
                          begin
                            parse_record_proc_directives(pd);

                            handle_calling_convention(pd);

                            { add definition to procsym }
                            proc_add_definition(pd);
                          end;

                        maybe_parse_hint_directives(pd);

                        parse_only:=oldparse_only;
                        fields_allowed:=false;
                        is_classdef:=false;
                      end
                      else
                      begin
                        if member_blocktype=bt_general then
                          begin
                            if (not fields_allowed)and(idtoken<>_CASE) then
                              Message(parser_e_field_not_allowed_here);
                            vdoptions:=[vd_record];
                            if classfields then
                              include(vdoptions,vd_class);
                            read_record_fields(vdoptions);
                          end
                        else if member_blocktype=bt_type then
                          types_dec(true)
                        else if member_blocktype=bt_const then
                          consts_dec(true)
                        else
                          internalerror(201001110);
                      end;
                end;
              end;
            _PROPERTY :
              begin
                struct_property_dec(is_classdef);
                fields_allowed:=false;
                is_classdef:=false;
              end;
            _CLASS:
              begin
                is_classdef:=false;
                { read class method/field/property }
                consume(_CLASS);
                { class modifier is only allowed for procedures, functions, }
                { constructors, destructors, fields and properties          }
                if not(token in [_FUNCTION,_PROCEDURE,_PROPERTY,_VAR,_CONSTRUCTOR,_DESTRUCTOR,_OPERATOR]) and
                   not((token=_ID) and (idtoken=_OPERATOR)) then
                  Message(parser_e_procedure_or_function_expected);

                is_classdef:=true;
              end;
            _PROCEDURE,
            _FUNCTION:
              begin
                oldparse_only:=parse_only;
                parse_only:=true;
                pd:=parse_proc_dec(current_structdef,as_procparsemode(is_classdef));

                { this is for error recovery as well as forward }
                { interface mappings, i.e. mapping to a method  }
                { which isn't declared yet                      }
                if assigned(pd) then
                  begin
                    parse_record_proc_directives(pd);

                    { since records have no inheritance don't allow non static
                      class methods. delphi do so. }
                    if is_classdef and not (po_staticmethod in pd.procoptions) then
                      MessagePos(pd.fileinfo, parser_e_class_methods_only_static_in_records);

                    handle_calling_convention(pd);

                    { add definition to procsym }
                    proc_add_definition(pd);
                  end;

                maybe_parse_hint_directives(pd);

                parse_only:=oldparse_only;
                fields_allowed:=false;
                is_classdef:=false;
              end;
            _CONSTRUCTOR :
              begin
                if not is_classdef then
                  Message(parser_e_no_constructor_in_records);
                if not is_classdef and (current_structdef.symtable.currentvisibility <> vis_public) then
                  Message(parser_w_constructor_should_be_public);

                { only 1 class constructor is allowed }
                if is_classdef and (oo_has_class_constructor in current_structdef.objectoptions) then
                  Message1(parser_e_only_one_class_constructor_allowed, current_structdef.objrealname^);

                oldparse_only:=parse_only;
                parse_only:=true;
                if is_classdef then
                  pd:=class_constructor_head
                else
                  pd:=constructor_head;
                parse_record_proc_directives(pd);
                handle_calling_convention(pd);

                { add definition to procsym }
                proc_add_definition(pd);

                maybe_parse_hint_directives(pd);

                parse_only:=oldparse_only;
                fields_allowed:=false;
                is_classdef:=false;
              end;
            _DESTRUCTOR :
              begin
                if not is_classdef then
                  Message(parser_e_no_destructor_in_records);

                { only 1 class destructor is allowed }
                if is_classdef and (oo_has_class_destructor in current_structdef.objectoptions) then
                  Message1(parser_e_only_one_class_destructor_allowed, current_structdef.objrealname^);

                oldparse_only:=parse_only;
                parse_only:=true;
                if is_classdef then
                  pd:=class_destructor_head
                else
                  pd:=destructor_head;
                parse_record_proc_directives(pd);
                handle_calling_convention(pd);

                { add definition to procsym }
                proc_add_definition(pd);

                maybe_parse_hint_directives(pd);

                parse_only:=oldparse_only;
                fields_allowed:=false;
                is_classdef:=false;
              end;
            _END :
              begin
                consume(_END);
                break;
              end;
            else
              consume(_ID); { Give a ident expected message, like tp7 }
          end;
        until false;
      end;

    { reads a record declaration }
    function record_dec(const n:tidstring;genericdef:tstoreddef;genericlist:TFPObjectList):tdef;
      var
         old_current_structdef: tabstractrecorddef;
         old_current_genericdef,
         old_current_specializedef: tstoreddef;
         old_parse_generic: boolean;
         recst: trecordsymtable;
      begin
         old_current_structdef:=current_structdef;
         old_current_genericdef:=current_genericdef;
         old_current_specializedef:=current_specializedef;
         old_parse_generic:=parse_generic;

         current_genericdef:=nil;
         current_specializedef:=nil;
         { create recdef }
         recst:=trecordsymtable.create(n,current_settings.packrecords);
         current_structdef:=trecorddef.create(n,recst);
         result:=current_structdef;
         { insert in symtablestack }
         symtablestack.push(recst);

         { usage of specialized type inside its generic template }
         if assigned(genericdef) then
           current_specializedef:=current_structdef
         { reject declaration of generic class inside generic class }
         else if assigned(genericlist) then
           current_genericdef:=current_structdef;

         { nested types of specializations are specializations as well }
         if assigned(old_current_structdef) and
             (df_specialization in old_current_structdef.defoptions) then
           include(current_structdef.defoptions,df_specialization);

         insert_generic_parameter_types(current_structdef,genericdef,genericlist);
         { when we are parsing a generic already then this is a generic as
           well }
         if old_parse_generic then
           include(current_structdef.defoptions, df_generic);
         parse_generic:=(df_generic in current_structdef.defoptions);
         if m_advanced_records in current_settings.modeswitches then
           parse_record_members
         else
           begin
             read_record_fields([vd_record]);
             consume(_END);
            end;
         { make the record size aligned }
         recst.addalignmentpadding;
         { restore symtable stack }
         symtablestack.pop(recst);
         if trecorddef(current_structdef).is_packed and is_managed_type(current_structdef) then
           Message(type_e_no_packed_inittable);
         { restore old state }
         parse_generic:=old_parse_generic;
         current_structdef:=old_current_structdef;
         current_genericdef:=old_current_genericdef;
         current_specializedef:=old_current_specializedef;
      end;


    { reads a type definition and returns a pointer to it }
    procedure read_named_type(var def : tdef;const name : TIDString;genericdef:tstoreddef;genericlist:TFPObjectList;parseprocvardir:boolean);
      var
        pt : tnode;
        tt2 : tdef;
        aktenumdef : tenumdef;
        s : TIDString;
        l,v : TConstExprInt;
        oldpackrecords : longint;
        defpos,storepos : tfileposinfo;

        procedure expr_type;
        var
           pt1,pt2 : tnode;
           lv,hv   : TConstExprInt;
           old_block_type : tblock_type;
           dospecialize : boolean;
        begin
           old_block_type:=block_type;
           dospecialize:=false;
           { use of current parsed object:
             classes, objects, records can be used also in themself }
           if (token=_ID) then
             if try_parse_structdef_nested_type(def,current_structdef,false) then
               exit;
           { Generate a specialization in FPC mode? }
           dospecialize:=not(m_delphi in current_settings.modeswitches) and try_to_consume(_SPECIALIZE);
           { we can't accept a equal in type }
           pt1:=comp_expr(false,true);
           if not dospecialize and
              try_to_consume(_POINTPOINT) then
             begin
               { get high value of range }
               pt2:=comp_expr(false,false);
               { make both the same type or give an error. This is not
                 done when both are integer values, because typecasting
                 between -3200..3200 will result in a signed-unsigned
                 conflict and give a range check error (PFV) }
               if not(is_integer(pt1.resultdef) and is_integer(pt2.resultdef)) then
                 inserttypeconv(pt1,pt2.resultdef);
               { both must be evaluated to constants now }
               if (pt1.nodetype=ordconstn) and
                  (pt2.nodetype=ordconstn) then
                 begin
                   lv:=tordconstnode(pt1).value;
                   hv:=tordconstnode(pt2).value;
                   { Check bounds }
                   if hv<lv then
                     message(parser_e_upper_lower_than_lower)
                   else if (lv.signed and (lv.svalue<0)) and (not hv.signed and (hv.uvalue>qword(high(int64)))) then
                     message(type_e_cant_eval_constant_expr)
                   else
                     begin
                       { All checks passed, create the new def }
                       case pt1.resultdef.typ of
                         enumdef :
                           def:=tenumdef.create_subrange(tenumdef(pt1.resultdef),lv.svalue,hv.svalue);
                         orddef :
                           begin
                             if is_char(pt1.resultdef) then
                               def:=torddef.create(uchar,lv,hv)
                             else
                               if is_boolean(pt1.resultdef) then
                                 def:=torddef.create(pasbool8,lv,hv)
                               else if is_signed(pt1.resultdef) then
                                 def:=torddef.create(range_to_basetype(lv,hv),lv,hv)
                               else
                                 def:=torddef.create(range_to_basetype(lv,hv),lv,hv);
                           end;
                       end;
                     end;
                 end
               else
                 Message(sym_e_error_in_type_def);
               pt2.free;
             end
           else
             begin
               { a simple type renaming or generic specialization }
               if (pt1.nodetype=typen) then
                 begin
                   def:=ttypenode(pt1).resultdef;
                   { Delphi mode specialization? }
                   if (m_delphi in current_settings.modeswitches) then
                     dospecialize:=token=_LSHARPBRACKET
                   else
                     { in non-Delphi modes we might get a inline specialization
                       without "specialize" or "<T>" of the same type we're
                       currently parsing, so we need to handle that special }
                     if not dospecialize and
                         assigned(ttypenode(pt1).typesym) and
                         (ttypenode(pt1).typesym.typ=typesym) and
                         (sp_generic_dummy in ttypenode(pt1).typesym.symoptions) and
                         assigned(current_structdef) and
                         (
                           (
                             not (m_delphi in current_settings.modeswitches) and
                             (ttypesym(ttypenode(pt1).typesym).typedef.typ=undefineddef) and
                             (df_generic in current_structdef.defoptions) and
                             (ttypesym(ttypenode(pt1).typesym).typedef.owner=current_structdef.owner) and
                             (upper(ttypenode(pt1).typesym.realname)=copy(current_structdef.objname^,1,pos('$',current_structdef.objname^)-1))
                           ) or (
                             (df_specialization in current_structdef.defoptions) and
                             (ttypesym(ttypenode(pt1).typesym).typedef=current_structdef.genericdef)
                           )
                         )
                         then
                       begin
                         def:=current_structdef;
                         { handle nested types }
                         post_comp_expr_gendef(def);
                       end;
                   if dospecialize then
                     begin
                       generate_specialization(def,false,name,nil,'');
                       { handle nested types }
                       post_comp_expr_gendef(def);
                     end
                   else
                     begin
                       if assigned(current_specializedef) and (def=current_specializedef.genericdef) then
                         begin
                           def:=current_specializedef
                         end
                       else if (def=current_genericdef) then
                         begin
                           def:=current_genericdef
                         end
                       else if (df_generic in def.defoptions) and
                           { TODO : check once nested generics are allowed }
                           not
                             (
                               parse_generic and
                               (current_genericdef.typ in [recorddef,objectdef]) and
                               (def.typ in [recorddef,objectdef]) and
                               (ttypenode(pt1).typesym<>nil) and
                               sym_is_owned_by(ttypenode(pt1).typesym,tabstractrecorddef(current_genericdef).symtable)
                             )
                           then
                         begin
                           Message(parser_e_no_generics_as_types);
                           def:=generrordef;
                         end
                       else if is_classhelper(def) then
                         begin
                           Message(parser_e_no_category_as_types);
                           def:=generrordef
                         end
                     end;
                 end
               else
                 Message(sym_e_error_in_type_def);
             end;
           pt1.free;
           block_type:=old_block_type;
        end;


      procedure set_dec;
        begin
          consume(_SET);
          consume(_OF);
          read_anon_type(tt2,true);
          if assigned(tt2) then
           begin
             case tt2.typ of
               { don't forget that min can be negativ  PM }
               enumdef :
                 if (tenumdef(tt2).min>=0) and
                    (tenumdef(tt2).max<=255) then
                  // !! def:=tsetdef.create(tt2,tenumdef(tt2.def).min,tenumdef(tt2.def).max))
                  def:=tsetdef.create(tt2,tenumdef(tt2).min,tenumdef(tt2).max)
                 else
                  Message(sym_e_ill_type_decl_set);
               orddef :
                 begin
                   if (torddef(tt2).ordtype<>uvoid) and
                      (torddef(tt2).ordtype<>uwidechar) and
                      (torddef(tt2).low>=0) then
                     // !! def:=tsetdef.create(tt2,torddef(tt2.def).low,torddef(tt2.def).high))
                     if Torddef(tt2).high>int64(high(byte)) then
                       message(sym_e_ill_type_decl_set)
                     else
                       def:=tsetdef.create(tt2,torddef(tt2).low.svalue,torddef(tt2).high.svalue)
                   else
                     Message(sym_e_ill_type_decl_set);
                 end;
               else
                 Message(sym_e_ill_type_decl_set);
             end;
           end
          else
           def:=generrordef;
        end;


      procedure array_dec(is_packed:boolean;genericdef:tstoreddef;genericlist:TFPObjectList);
        var
          lowval,
          highval   : TConstExprInt;
          indexdef  : tdef;
          hdef      : tdef;
          arrdef    : tarraydef;

        procedure setdefdecl(def:tdef);
          begin
            case def.typ of
              enumdef :
                begin
                  lowval:=tenumdef(def).min;
                  highval:=tenumdef(def).max;
                  if (m_fpc in current_settings.modeswitches) and
                     (tenumdef(def).has_jumps) then
                   Message(type_e_array_index_enums_with_assign_not_possible);
                  indexdef:=def;
                end;
              orddef :
                begin
                  if torddef(def).ordtype in [uchar,
                    u8bit,u16bit,
                    s8bit,s16bit,s32bit,
{$ifdef cpu64bitaddr}
                    u32bit,s64bit,
{$endif cpu64bitaddr}
                    pasbool8,pasbool16,pasbool32,pasbool64,
                    bool8bit,bool16bit,bool32bit,bool64bit,
                    uwidechar] then
                    begin
                       lowval:=torddef(def).low;
                       highval:=torddef(def).high;
                       indexdef:=def;
                    end
                  else
                    Message1(parser_e_type_cant_be_used_in_array_index,def.typename);
                end;
              else
                Message(sym_e_error_in_type_def);
            end;
          end;

        var
          old_current_genericdef,
          old_current_specializedef: tstoreddef;
          old_parse_generic: boolean;
        begin
           old_current_genericdef:=current_genericdef;
           old_current_specializedef:=current_specializedef;
           old_parse_generic:=parse_generic;

           current_genericdef:=nil;
           current_specializedef:=nil;
           arrdef:=nil;
           consume(_ARRAY);
           { open array? }
           if try_to_consume(_LECKKLAMMER) then
             begin
                { defaults }
                indexdef:=generrordef;
                { use defaults which don't overflow the compiler }
                lowval:=0;
                highval:=0;
                repeat
                  { read the expression and check it, check apart if the
                    declaration is an enum declaration because that needs to
                    be parsed by readtype (PFV) }
                  if token=_LKLAMMER then
                   begin
                     read_anon_type(hdef,true);
                     setdefdecl(hdef);
                   end
                  else
                   begin
                     pt:=expr(true);
                     if pt.nodetype=typen then
                       setdefdecl(pt.resultdef)
                     else
                       begin
                         if pt.nodetype=rangen then
                           begin
                             { check the expression only if we are not in a generic declaration }
                             if not(parse_generic) then
                               begin
                                 if (trangenode(pt).left.nodetype=ordconstn) and
                                    (trangenode(pt).right.nodetype=ordconstn) then
                                   begin
                                     { make both the same type or give an error. This is not
                                       done when both are integer values, because typecasting
                                       between -3200..3200 will result in a signed-unsigned
                                       conflict and give a range check error (PFV) }
                                     if not(is_integer(trangenode(pt).left.resultdef) and is_integer(trangenode(pt).left.resultdef)) then
                                       inserttypeconv(trangenode(pt).left,trangenode(pt).right.resultdef);
                                     lowval:=tordconstnode(trangenode(pt).left).value;
                                     highval:=tordconstnode(trangenode(pt).right).value;
                                     if highval<lowval then
                                      begin
                                        Message(parser_e_array_lower_less_than_upper_bound);
                                        highval:=lowval;
                                      end
                                     else if (lowval<int64(low(asizeint))) or
                                             (highval>high(asizeint)) then
                                       begin
                                         Message(parser_e_array_range_out_of_bounds);
                                         lowval :=0;
                                         highval:=0;
                                       end;
                                     if is_integer(trangenode(pt).left.resultdef) then
                                       range_to_type(lowval,highval,indexdef)
                                     else
                                       indexdef:=trangenode(pt).left.resultdef;
                                   end
                                 else
                                   Message(type_e_cant_eval_constant_expr);
                               end;
                           end
                         else
                           Message(sym_e_error_in_type_def)
                       end;
                     pt.free;
                   end;

                  { if the array is already created add the new arrray
                    as element of the existing array, otherwise create a new array }
                  if assigned(arrdef) then
                    begin
                      arrdef.elementdef:=tarraydef.create(lowval.svalue,highval.svalue,indexdef);
                      arrdef:=tarraydef(arrdef.elementdef);
                    end
                  else
                    begin
                      arrdef:=tarraydef.create(lowval.svalue,highval.svalue,indexdef);
                      def:=arrdef;
                    end;
                  if is_packed then
                    include(arrdef.arrayoptions,ado_IsBitPacked);

                  if token=_COMMA then
                    consume(_COMMA)
                  else
                    break;
                until false;
                consume(_RECKKLAMMER);
             end
           else
             begin
                if is_packed then
                  Message(parser_e_packed_dynamic_open_array);
                arrdef:=tarraydef.create(0,-1,s32inttype);
                include(arrdef.arrayoptions,ado_IsDynamicArray);
                def:=arrdef;
             end;
           if assigned(arrdef) then
             begin
               { usage of specialized type inside its generic template }
               if assigned(genericdef) then
                 current_specializedef:=arrdef
               { reject declaration of generic class inside generic class }
               else if assigned(genericlist) then
                 current_genericdef:=arrdef;
               symtablestack.push(arrdef.symtable);
               insert_generic_parameter_types(arrdef,genericdef,genericlist);
               { there are two possibilties for the following to be true:
                 * the array declaration itself is generic
                 * the array is declared inside a generic
                 in both cases we need "parse_generic" and "current_genericdef"
                 so that e.g. specializations of another generic inside the
                 current generic can be used (either inline ones or "type" ones) }
               parse_generic:=(df_generic in arrdef.defoptions) or old_parse_generic;
               if parse_generic and not assigned(current_genericdef) then
                 current_genericdef:=old_current_genericdef;
             end;
           consume(_OF);
           read_anon_type(tt2,true);
           { set element type of the last array definition }
           if assigned(arrdef) then
             begin
               symtablestack.pop(arrdef.symtable);
               arrdef.elementdef:=tt2;
               if is_packed and
                  is_managed_type(tt2) then
                 Message(type_e_no_packed_inittable);
             end;
           { restore old state }
           parse_generic:=old_parse_generic;
           current_genericdef:=old_current_genericdef;
           current_specializedef:=old_current_specializedef;
        end;

        function procvar_dec(genericdef:tstoreddef;genericlist:TFPObjectList):tdef;
          var
            is_func:boolean;
            pd:tabstractprocdef;
            newtype:ttypesym;
            old_current_genericdef,
            old_current_specializedef: tstoreddef;
            old_parse_generic: boolean;
          begin
            old_current_genericdef:=current_genericdef;
            old_current_specializedef:=current_specializedef;
            old_parse_generic:=parse_generic;

            current_genericdef:=nil;
            current_specializedef:=nil;

            is_func:=(token=_FUNCTION);
            consume(token);
            pd:=tprocvardef.create(normal_function_level);

            { usage of specialized type inside its generic template }
            if assigned(genericdef) then
              current_specializedef:=pd
            { reject declaration of generic class inside generic class }
            else if assigned(genericlist) then
              current_genericdef:=pd;
            symtablestack.push(pd.parast);
            insert_generic_parameter_types(pd,genericdef,genericlist);
            { there are two possibilties for the following to be true:
              * the procvar declaration itself is generic
              * the procvar is declared inside a generic
              in both cases we need "parse_generic" and "current_genericdef"
              so that e.g. specializations of another generic inside the
              current generic can be used (either inline ones or "type" ones) }
            parse_generic:=(df_generic in pd.defoptions) or old_parse_generic;
            if parse_generic and not assigned(current_genericdef) then
              current_genericdef:=old_current_genericdef;
            { don't allow to add defs to the symtable - use it for type param search only }
            tparasymtable(pd.parast).readonly:=true;

            if token=_LKLAMMER then
              parse_parameter_dec(pd);
            if is_func then
              begin
                consume(_COLON);
                single_type(pd.returndef,[]);
              end;
            if try_to_consume(_OF) then
              begin
                consume(_OBJECT);
                include(pd.procoptions,po_methodpointer);
              end
            else if (m_nested_procvars in current_settings.modeswitches) and
                    try_to_consume(_IS) then
              begin
                consume(_NESTED);
                pd.parast.symtablelevel:=normal_function_level+1;
                pd.check_mark_as_nested;
              end;
            symtablestack.pop(pd.parast);
            tparasymtable(pd.parast).readonly:=false;
            result:=pd;
            { possible proc directives }
            if parseprocvardir then
              begin
                if check_proc_directive(true) then
                  begin
                    newtype:=ttypesym.create('unnamed',result);
                    parse_var_proc_directives(tsym(newtype));
                    newtype.typedef:=nil;
                    result.typesym:=nil;
                    newtype.free;
                  end;
                { Add implicit hidden parameters and function result }
                handle_calling_convention(pd);
              end;
            { restore old state }
            parse_generic:=old_parse_generic;
            current_genericdef:=old_current_genericdef;
            current_specializedef:=old_current_specializedef;
          end;

      const
        SingleTypeOptionsInTypeBlock:array[Boolean] of TSingleTypeOptions = ([],[stoIsForwardDef]);
      var
        p  : tnode;
        hdef : tdef;
        enumdupmsg, first, is_specialize : boolean;
        oldlocalswitches : tlocalswitches;
        bitpacking: boolean;
        stitem: psymtablestackitem;
        sym: tsym;
        st: tsymtable;
      begin
         def:=nil;
         case token of
            _STRING,_FILE:
              begin
                single_type(def,[stoAllowTypeDef]);
              end;
           _LKLAMMER:
              begin
                consume(_LKLAMMER);
                first:=true;
                { allow negativ value_str }
                l:=int64(-1);
                enumdupmsg:=false;
                { check that we are not adding an enum from specialization
                  we can't just use current_specializedef because of inner types
                  like specialize array of record }
                is_specialize:=false;
                stitem:=symtablestack.stack;
                while assigned(stitem) do
                  begin
                    { check records, classes and arrays because they can be specialized }
                    if stitem^.symtable.symtabletype in [recordsymtable,ObjectSymtable,arraysymtable] then
                      begin
                        is_specialize:=is_specialize or (df_specialization in tstoreddef(stitem^.symtable.defowner).defoptions);
                        stitem:=stitem^.next;
                      end
                    else
                      break;
                  end;
                if not is_specialize then
                  aktenumdef:=tenumdef.create
                else
                  aktenumdef:=nil;
                repeat
                  { if it is a specialization then search the first enum member
                    and get the member owner instead of just created enumdef }
                  if not assigned(aktenumdef) then
                    begin
                      searchsym(pattern,sym,st);
                      if sym.typ=enumsym then
                        aktenumdef:=tenumsym(sym).definition
                      else
                        internalerror(201101021);
                    end;
                  s:=orgpattern;
                  defpos:=current_tokenpos;
                  consume(_ID);
                  { only allow assigning of specific numbers under fpc mode }
                  if not(m_tp7 in current_settings.modeswitches) and
                     (
                      { in fpc mode also allow := to be compatible
                        with previous 1.0.x versions }
                      ((m_fpc in current_settings.modeswitches) and
                       try_to_consume(_ASSIGNMENT)) or
                      try_to_consume(_EQ)
                     ) then
                    begin
                       oldlocalswitches:=current_settings.localswitches;
                       include(current_settings.localswitches,cs_allow_enum_calc);
                       p:=comp_expr(true,false);
                       current_settings.localswitches:=oldlocalswitches;
                       if (p.nodetype=ordconstn) then
                        begin
                          { we expect an integer or an enum of the
                            same type }
                          if is_integer(p.resultdef) or
                             is_char(p.resultdef) or
                             equal_defs(p.resultdef,aktenumdef) then
                           v:=tordconstnode(p).value
                          else
                           IncompatibleTypes(p.resultdef,s32inttype);
                        end
                       else
                        Message(parser_e_illegal_expression);
                       p.free;
                       { please leave that a note, allows type save }
                       { declarations in the win32 units ! }
                       if (not first) and (v<=l) and (not enumdupmsg) then
                        begin
                          Message(parser_n_duplicate_enum);
                          enumdupmsg:=true;
                        end;
                       l:=v;
                    end
                  else
                    inc(l.svalue);
                  first:=false;
                  { don't generate enum members is this is a specialization because aktenumdef is copied from the generic type }
                  if not is_specialize then
                    begin
                      storepos:=current_tokenpos;
                      current_tokenpos:=defpos;
                      tenumsymtable(aktenumdef.symtable).insert(tenumsym.create(s,aktenumdef,longint(l.svalue)));
                      if not (cs_scopedenums in current_settings.localswitches) then
                        tstoredsymtable(aktenumdef.owner).insert(tenumsym.create(s,aktenumdef,longint(l.svalue)));
                      current_tokenpos:=storepos;
                    end;
                until not try_to_consume(_COMMA);
                def:=aktenumdef;
                consume(_RKLAMMER);
              end;
            _ARRAY:
              begin
                array_dec(false,genericdef,genericlist);
              end;
            _SET:
              begin
                set_dec;
              end;
           _CARET:
              begin
                consume(_CARET);
                single_type(tt2,SingleTypeOptionsInTypeBlock[block_type=bt_type]);
                def:=tpointerdef.create(tt2);
                if tt2.typ=forwarddef then
                  current_module.checkforwarddefs.add(def);
              end;
            _RECORD:
              begin
                consume(token);
                if (idtoken=_HELPER) and (m_advanced_records in current_settings.modeswitches) then
                  begin
                    consume(_HELPER);
                    def:=object_dec(odt_helper,name,genericdef,genericlist,nil,ht_record);
                  end
                else
                  def:=record_dec(name,genericdef,genericlist);
              end;
            _PACKED,
            _BITPACKED:
              begin
                bitpacking :=
                  (cs_bitpacking in current_settings.localswitches) or
                  (token = _BITPACKED);
                consume(token);
                if token=_ARRAY then
                  array_dec(bitpacking,genericdef,genericlist)
                else if token=_SET then
                  set_dec
                else if token=_FILE then
                  single_type(def,[stoAllowTypeDef])
                else
                  begin
                    oldpackrecords:=current_settings.packrecords;
                    if (not bitpacking) or
                       (token in [_CLASS,_OBJECT]) then
                      current_settings.packrecords:=1
                    else
                      current_settings.packrecords:=bit_alignment;
                    case token of
                      _CLASS :
                        begin
                          consume(_CLASS);
                          def:=object_dec(odt_class,name,genericdef,genericlist,nil,ht_none);
                        end;
                      _OBJECT :
                        begin
                          consume(_OBJECT);
                          def:=object_dec(odt_object,name,genericdef,genericlist,nil,ht_none);
                        end;
                      else begin
                        consume(_RECORD);
                        def:=record_dec(name,genericdef,genericlist);
                      end;
                    end;
                    current_settings.packrecords:=oldpackrecords;
                  end;
              end;
            _DISPINTERFACE :
              begin
                { need extra check here since interface is a keyword
                  in all pascal modes }
                if not(m_class in current_settings.modeswitches) then
                  Message(parser_f_need_objfpc_or_delphi_mode);
                consume(token);
                def:=object_dec(odt_dispinterface,name,genericdef,genericlist,nil,ht_none);
              end;
            _CLASS :
              begin
                consume(token);
                { Delphi only allows class of in type blocks }
                if (token=_OF) and
                   (
                    not(m_delphi in current_settings.modeswitches) or
                    (block_type=bt_type)
                   ) then
                  begin
                    consume(_OF);
                    single_type(hdef,SingleTypeOptionsInTypeBlock[block_type=bt_type]);
                    if is_class(hdef) or
                       is_objcclass(hdef) then
                      def:=tclassrefdef.create(hdef)
                    else
                      if hdef.typ=forwarddef then
                        begin
                          def:=tclassrefdef.create(hdef);
                          current_module.checkforwarddefs.add(def);
                        end
                    else
                      Message1(type_e_class_or_objcclass_type_expected,hdef.typename);
                  end
                else
                if (idtoken=_HELPER) then
                  begin
                    consume(_HELPER);
                    def:=object_dec(odt_helper,name,genericdef,genericlist,nil,ht_class);
                  end
                else
                  def:=object_dec(odt_class,name,genericdef,genericlist,nil,ht_none);
              end;
            _CPPCLASS :
              begin
                consume(token);
                def:=object_dec(odt_cppclass,name,genericdef,genericlist,nil,ht_none);
              end;
            _OBJCCLASS :
              begin
                if not(m_objectivec1 in current_settings.modeswitches) then
                  Message(parser_f_need_objc);

                consume(token);
                def:=object_dec(odt_objcclass,name,genericdef,genericlist,nil,ht_none);
              end;
            _INTERFACE :
              begin
                { need extra check here since interface is a keyword
                  in all pascal modes }
                if not(m_class in current_settings.modeswitches) then
                  Message(parser_f_need_objfpc_or_delphi_mode);
                consume(token);
                if current_settings.interfacetype=it_interfacecom then
                  def:=object_dec(odt_interfacecom,name,genericdef,genericlist,nil,ht_none)
                else {it_interfacecorba}
                  def:=object_dec(odt_interfacecorba,name,genericdef,genericlist,nil,ht_none);
              end;
            _OBJCPROTOCOL :
               begin
                if not(m_objectivec1 in current_settings.modeswitches) then
                  Message(parser_f_need_objc);

                consume(token);
                def:=object_dec(odt_objcprotocol,name,genericdef,genericlist,nil,ht_none);
               end;
            _OBJCCATEGORY :
               begin
                if not(m_objectivec1 in current_settings.modeswitches) then
                  Message(parser_f_need_objc);

                consume(token);
                def:=object_dec(odt_objccategory,name,genericdef,genericlist,nil,ht_none);
               end;
            _OBJECT :
              begin
                consume(token);
                def:=object_dec(odt_object,name,genericdef,genericlist,nil,ht_none);
              end;
            _PROCEDURE,
            _FUNCTION:
              begin
                def:=procvar_dec(genericdef,genericlist);
              end;
            _ID:
              if idtoken=_REFERENCE then // TODO: $mode Delphi only?
                def:=parse_method_reference(name)
              else
                expr_type;
            else
              if (token=_KLAMMERAFFE) and (m_iso in current_settings.modeswitches) then
                begin
                  consume(_KLAMMERAFFE);
                  single_type(tt2,SingleTypeOptionsInTypeBlock[block_type=bt_type]);
                  def:=tpointerdef.create(tt2);
                  if tt2.typ=forwarddef then
                    current_module.checkforwarddefs.add(def);
                end
              else
                expr_type;
         end;

         if def=nil then
          def:=generrordef;
      end;


    procedure read_anon_type(var def : tdef;parseprocvardir:boolean);
      begin
        read_named_type(def,'',nil,nil,parseprocvardir);
      end;


    procedure write_persistent_type_info(st:tsymtable);
      var
        i : longint;
        def : tdef;
        vmtwriter  : TVMTWriter;
      begin
        for i:=0 to st.DefList.Count-1 do
          begin
            def:=tdef(st.DefList[i]);
            case def.typ of
              recorddef :
                write_persistent_type_info(trecorddef(def).symtable);
              objectdef :
                begin
                  { Skip generics and forward defs }
                  if (df_generic in def.defoptions) or
                     (oo_is_forward in tobjectdef(def).objectoptions) then
                    continue;
                  write_persistent_type_info(tobjectdef(def).symtable);
                  { Write also VMT if not done yet }
                  if not(ds_vmt_written in def.defstates) then
                    begin
                      vmtwriter:=TVMTWriter.create(tobjectdef(def));
                      if is_interface(tobjectdef(def)) then
                        vmtwriter.writeinterfaceids;
                      if (oo_has_vmt in tobjectdef(def).objectoptions) then
                        vmtwriter.writevmt;
                      vmtwriter.free;
                      include(def.defstates,ds_vmt_written);
                    end;
                end;
              procdef :
                begin
                  if assigned(tprocdef(def).localst) and
                     (tprocdef(def).localst.symtabletype=localsymtable) then
                    write_persistent_type_info(tprocdef(def).localst);
                  if assigned(tprocdef(def).parast) then
                    write_persistent_type_info(tprocdef(def).parast);
                end;
            end;
            { generate always persistent tables for types in the interface so it can
              be reused in other units and give always the same pointer location. }
            { Init }
            if (
                assigned(def.typesym) and
                (st.symtabletype=globalsymtable) and
                not is_objc_class_or_protocol(def)
               ) or
               is_managed_type(def) or
               (ds_init_table_used in def.defstates) then
              RTTIWriter.write_rtti(def,initrtti);
            { RTTI }
            if (
                assigned(def.typesym) and
                (st.symtabletype=globalsymtable) and
                not is_objc_class_or_protocol(def)
               ) or
               (ds_rtti_table_used in def.defstates) then
              RTTIWriter.write_rtti(def,fullrtti);
          end;
      end;

end.
