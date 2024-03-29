{
    Copyright (c) 2011

    Contains different functions that are used in the context of 
    parsing generics.

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
unit pgenutil;

{$i fpcdefs.inc}

interface

uses
  { common }
  cclasses,
  { symtable }
  symtype,symdef;

    procedure generate_specialization(var tt:tdef;parse_class_parent:boolean;_prettyname:string;parsedtype:tdef;symname:string);
    function parse_generic_parameters:TFPObjectList;
    procedure insert_generic_parameter_types(def:tstoreddef;genericdef:tstoreddef;genericlist:TFPObjectList);

implementation

uses
  { common }
  cutils,
  { global }
  globals,globtype,tokens,verbose,
  { symtable }
  symconst,symbase,symsym,symtable,
  { modules }
  fmodule,
  { pass 1 }
  htypechk,
  node,nobj,nmem,
  { parser }
  scanner,
  pbase,pexpr,pdecsub,ptype;


    procedure generate_specialization(var tt:tdef;parse_class_parent:boolean;_prettyname:string;parsedtype:tdef;symname:string);
      var
        st  : TSymtable;
        srsym : tsym;
        pt2 : tnode;
        found,
        first,
        err : boolean;
        i,
        gencount : longint;
        genericdef : tstoreddef;
        generictype : ttypesym;
        genericdeflist : TFPObjectList;
        generictypelist : TFPObjectList;
        oldsymtablestack   : tsymtablestack;
        oldextendeddefs    : TFPHashObjectList;
        hmodule : tmodule;
        pu : tused_unit;
        prettyname : ansistring;
        uspecializename,
        countstr,genname,ugenname,specializename : string;
        vmtbuilder : TVMTBuilder;
        specializest : tsymtable;
        item : tobject;
        old_current_structdef : tabstractrecorddef;
        old_current_genericdef,old_current_specializedef : tstoreddef;
        tempst : tglobalsymtable;
        old_block_type: tblock_type;
        hashedid: thashedidstring;
      begin
        { retrieve generic def that we are going to replace }
        genericdef:=tstoreddef(tt);
        tt:=nil;

        { either symname must be given or genericdef needs to be valid }
        if (symname='') and
            (not assigned(genericdef) or
            not assigned(genericdef.typesym) or
            (genericdef.typesym.typ<>typesym)) then
           internalerror(2011042701);

        { Only parse the parameters for recovery or
          for recording in genericbuf }
        if parse_generic then
          begin
            if not try_to_consume(_LT) then
              consume(_LSHARPBRACKET);
            gencount:=0;
            repeat
              pt2:=factor(false,true);
              pt2.free;
              inc(gencount);
            until not try_to_consume(_COMMA);
            if not try_to_consume(_GT) then
              consume(_RSHARPBRACKET);
            { we need to return a def that can later pass some checks like
              whether it's an interface or not }
            if parse_generic and (not assigned(tt) or (tt.typ=undefineddef)) then
              begin
                if (symname='') and (df_generic in genericdef.defoptions) then
                  { this happens in non-Delphi modes }
                  tt:=genericdef
                else
                  begin
                    { find the corresponding generic symbol so that any checks
                      done on the returned def will be handled correctly }
                    str(gencount,countstr);
                    if symname='' then
                      genname:=ttypesym(genericdef.typesym).realname
                    else
                      genname:=symname;
                    genname:=genname+'$'+countstr;
                    ugenname:=upper(genname);
                    if not searchsym(ugenname,srsym,st) or
                        (srsym.typ<>typesym) then
                      begin
                        identifier_not_found(genname);
                        exit;
                      end;
                    tt:=ttypesym(srsym).typedef;
                    { this happens in non-Delphi modes if we encounter a
                      specialization of the generic class or record we're
                      currently parsing }
                    if (tt.typ=errordef) and assigned(current_structdef) and
                        (current_structdef.objname^=ugenname) then
                      tt:=current_structdef;
                  end;
              end;
            exit;
          end;

        if not assigned(parsedtype) and not try_to_consume(_LT) then
          consume(_LSHARPBRACKET);

        generictypelist:=TFPObjectList.create(false);
        genericdeflist:=TFPObjectList.Create(false);

        { Parse type parameters }
        err:=false;
        { set the block type to type, so that the parsed type are returned as
          ttypenode (e.g. classes are in non type-compatible blocks returned as
          tloadvmtaddrnode) }
        old_block_type:=block_type;
        { if parsedtype is set, then the first type identifer was already parsed
          (happens in inline specializations) and thus we only need to parse
          the remaining types and do as if the first one was already given }
        first:=not assigned(parsedtype);
        if assigned(parsedtype) then
          begin
            genericdeflist.Add(parsedtype);
            specializename:='$'+parsedtype.typesym.realname;
            prettyname:=parsedtype.typesym.prettyname;
          end
        else
          begin
            specializename:='';
            prettyname:='';
          end;
        while not (token in [_GT,_RSHARPBRACKET]) do
          begin
            { "first" is set to false at the end of the loop! }
            if not first then
              consume(_COMMA);
            block_type:=bt_type;
            pt2:=factor(false,true);
            if pt2.nodetype=typen then
              begin
                if df_generic in pt2.resultdef.defoptions then
                  Message(parser_e_no_generics_as_params);
                genericdeflist.Add(pt2.resultdef);
                if not assigned(pt2.resultdef.typesym) then
                  message(type_e_generics_cannot_reference_itself)
                else
                  begin
                    specializename:=specializename+'$'+pt2.resultdef.typesym.realname;
                    if first then
                      prettyname:=prettyname+pt2.resultdef.typesym.prettyname
                    else
                      prettyname:=prettyname+','+pt2.resultdef.typesym.prettyname;
                  end;
              end
            else
              begin
                Message(type_e_type_id_expected);
                err:=true;
              end;
            pt2.free;
            first:=false;
          end;
        block_type:=old_block_type;

        if err then
          begin
            try_to_consume(_RSHARPBRACKET);
            exit;
          end;

        { search a generic with the given count of params }
        countstr:='';
        str(genericdeflist.Count,countstr);
        { use the name of the symbol as procvars return a user friendly version
          of the name }
        if symname='' then
          genname:=ttypesym(genericdef.typesym).realname
        else
          genname:=symname;
        { in case of non-Delphi mode the type name could already be a generic
          def (but maybe the wrong one) }
        if assigned(genericdef) and (df_generic in genericdef.defoptions) then
          begin
            { remove the type count suffix from the generic's name }
            for i:=Length(genname) downto 1 do
              if genname[i]='$' then
                begin
                  genname:=copy(genname,1,i-1);
                  break;
                end;
          end;
        genname:=genname+'$'+countstr;
        ugenname:=upper(genname);

        if assigned(genericdef) and (genericdef.owner.symtabletype in [objectsymtable,recordsymtable]) then
          begin
            if genericdef.owner.symtabletype = objectsymtable then
              found:=searchsym_in_class(tobjectdef(genericdef.owner.defowner),tobjectdef(genericdef.owner.defowner),ugenname,srsym,st,false)
            else
              found:=searchsym_in_record(tabstractrecorddef(genericdef.owner.defowner),ugenname,srsym,st);
          end
        else
          found:=searchsym(ugenname,srsym,st);

        if not found or (srsym.typ<>typesym) then
          begin
            identifier_not_found(genname);
            genericdeflist.Free;
            generictypelist.Free;
            exit;
          end;

        { we've found the correct def }
        genericdef:=tstoreddef(ttypesym(srsym).typedef);

        { build the new type's name }
        specializename:=genname+specializename;
        uspecializename:=upper(specializename);
        prettyname:=genericdef.typesym.prettyname+'<'+prettyname+'>';

        { select the symtable containing the params }
        case genericdef.typ of
          procdef:
            st:=genericdef.GetSymtable(gs_para);
          objectdef,
          recorddef:
            st:=genericdef.GetSymtable(gs_record);
          arraydef:
            st:=tarraydef(genericdef).symtable;
          procvardef:
            st:=genericdef.GetSymtable(gs_para);
          else
            internalerror(200511182);
        end;

        { build the list containing the types for the generic params }
        gencount:=0;
        for i:=0 to st.SymList.Count-1 do
          begin
            srsym:=tsym(st.SymList[i]);
            if sp_generic_para in srsym.symoptions then
              begin
                if gencount=genericdeflist.Count then
                  internalerror(2011042702);
                generictype:=ttypesym.create(srsym.realname,tdef(genericdeflist[gencount]));
                generictypelist.add(generictype);
                inc(gencount);
              end;
          end;


        { Special case if we are referencing the current defined object }
        if assigned(current_structdef) and
           (current_structdef.objname^=uspecializename) then
          tt:=current_structdef;

        { decide in which symtable to put the specialization }
        if current_module.is_unit and current_module.in_interface then
          specializest:=current_module.globalsymtable
        else
          specializest:=current_module.localsymtable;

        { Can we reuse an already specialized type? }
        if not assigned(tt) then
          begin
            hashedid.id:=uspecializename;

            srsym:=tsym(specializest.findwithhash(hashedid));
            if assigned(srsym) then
              begin
                if srsym.typ<>typesym then
                  internalerror(200710171);
                tt:=ttypesym(srsym).typedef;
              end
            else
              { the generic could have been specialized in the globalsymtable
                already, so search there as well }
              if (specializest<>current_module.globalsymtable) and assigned(current_module.globalsymtable) then
                begin
                  srsym:=tsym(current_module.globalsymtable.findwithhash(hashedid));
                  if assigned(srsym) then
                    begin
                      if srsym.typ<>typesym then
                        internalerror(2011121101);
                      tt:=ttypesym(srsym).typedef;
                    end;
                end;
          end;

        if not assigned(tt) then
          begin
            { Setup symtablestack at definition time
              to get types right, however this is not perfect, we should probably record
              the resolved symbols }
            oldsymtablestack:=symtablestack;
            oldextendeddefs:=current_module.extendeddefs;
            current_module.extendeddefs:=TFPHashObjectList.create(true);
            symtablestack:=tdefawaresymtablestack.create;
            if not assigned(genericdef) then
              internalerror(200705151);
            hmodule:=find_module_from_symtable(genericdef.owner);
            if hmodule=nil then
              internalerror(200705152);
            pu:=tused_unit(hmodule.used_units.first);
            while assigned(pu) do
              begin
                if not assigned(pu.u.globalsymtable) then
                  internalerror(200705153);
                symtablestack.push(pu.u.globalsymtable);
                pu:=tused_unit(pu.next);
              end;

            if assigned(hmodule.globalsymtable) then
              symtablestack.push(hmodule.globalsymtable);

            { push the localsymtable if needed }
            if (hmodule<>current_module) or not current_module.in_interface then
              symtablestack.push(hmodule.localsymtable);

            { push a temporary global symtable so that the specialization is
              added to the correct symtable; this symtable does not contain
              any other symbols, so that the type resolution can not be
              influenced by symbols in the current unit }
            tempst:=tspecializesymtable.create(current_module.modulename^,current_module.moduleid);
            symtablestack.push(tempst);

            { Reparse the original type definition }
            if not err then
              begin
                if parse_class_parent then
                  begin
                    old_current_structdef:=current_structdef;
                    old_current_genericdef:=current_genericdef;
                    old_current_specializedef:=current_specializedef;

                    if genericdef.owner.symtabletype in [recordsymtable,objectsymtable] then
                      current_structdef:=tabstractrecorddef(genericdef.owner.defowner)
                    else
                      current_structdef:=nil;
                    current_genericdef:=nil;
                    current_specializedef:=nil;
                  end;

                { First a new typesym so we can reuse this specialization and
                  references to this specialization can be handled }
                srsym:=ttypesym.create(specializename,generrordef);
                specializest.insert(srsym);

                { specializations are declarations as such it is the wisest to
                  declare set the blocktype to "type"; otherwise we'll
                  experience unexpected side effects like the addition of
                  classrefdefs if we have a generic that's derived from another
                  generic }
                old_block_type:=block_type;
                block_type:=bt_type;

                if not assigned(genericdef.generictokenbuf) then
                  internalerror(200511171);
                current_scanner.startreplaytokens(genericdef.generictokenbuf,
                  genericdef.change_endian);
                read_named_type(tt,specializename,genericdef,generictypelist,false);
                ttypesym(srsym).typedef:=tt;
                tt.typesym:=srsym;

                if _prettyname<>'' then
                  ttypesym(tt.typesym).fprettyname:=_prettyname
                else
                  ttypesym(tt.typesym).fprettyname:=prettyname;

                { Note regarding hint directives:
                  There is no need to remove the flags for them from the
                  specialized generic symbol, because hint directives that
                  follow the specialization are handled by the code in
                  pdecl.types_dec and added to the type symbol.
                  E.g.: TFoo = TBar<Blubb> deprecated;
                  Here the symbol TBar$1$Blubb will contain the
                  "sp_hint_deprecated" flag while the TFoo symbol won't.}

                case tt.typ of
                  { Build VMT indexes for classes and read hint directives }
                  objectdef:
                    begin
                      try_consume_hintdirective(srsym.symoptions,srsym.deprecatedmsg);
                      consume(_SEMICOLON);

                      vmtbuilder:=TVMTBuilder.Create(tobjectdef(tt));
                      vmtbuilder.generate_vmt;
                      vmtbuilder.free;
                    end;
                  { handle params, calling convention, etc }
                  procvardef:
                    begin
                      if not check_proc_directive(true) then
                        begin
                          try_consume_hintdirective(ttypesym(srsym).symoptions,ttypesym(srsym).deprecatedmsg);
                          consume(_SEMICOLON);
                        end;
                      parse_var_proc_directives(ttypesym(srsym));
                      handle_calling_convention(tprocvardef(tt));
                      if try_consume_hintdirective(ttypesym(srsym).symoptions,ttypesym(srsym).deprecatedmsg) then
                        consume(_SEMICOLON);
                    end;
                  else
                    { parse hint directives for records and arrays }
                    begin
                      try_consume_hintdirective(srsym.symoptions,srsym.deprecatedmsg);
                      consume(_SEMICOLON);
                    end;
                end;
                { Consume the semicolon if it is also recorded }
                try_to_consume(_SEMICOLON);

                block_type:=old_block_type;
                if parse_class_parent then
                  begin
                    current_structdef:=old_current_structdef;
                    current_genericdef:=old_current_genericdef;
                    current_specializedef:=old_current_specializedef;
                  end;
              end;

            { extract all created symbols and defs from the temporary symtable
              and add them to the specializest }
            for i:=0 to tempst.SymList.Count-1 do
              begin
                item:=tempst.SymList.Items[i];
                specializest.SymList.Add(tempst.SymList.NameOfIndex(i),item);
                tsym(item).Owner:=specializest;
                tempst.SymList.Extract(item);
              end;

            for i:=0 to tempst.DefList.Count-1 do
              begin
                item:=tempst.DefList.Items[i];
                specializest.DefList.Add(item);
                tdef(item).owner:=specializest;
                tempst.DefList.Extract(item);
              end;

            tempst.free;

            { Restore symtablestack }
            current_module.extendeddefs.free;
            current_module.extendeddefs:=oldextendeddefs;
            symtablestack.free;
            symtablestack:=oldsymtablestack;
          end;

        if not (token in [_GT, _RSHARPBRACKET]) then
          begin
            consume(_RSHARPBRACKET);
            exit;
          end
        else
          consume(token);

        genericdeflist.free;
        generictypelist.free;
        if assigned(genericdef) then
          begin
            { check the hints of the found generic symbol }
            srsym:=genericdef.typesym;
            check_hints(srsym,srsym.symoptions,srsym.deprecatedmsg);
          end;
      end;


    function parse_generic_parameters:TFPObjectList;
      var
        generictype : ttypesym;
      begin
        result:=TFPObjectList.Create(false);
        repeat
          if token=_ID then
            begin
              generictype:=ttypesym.create(orgpattern,cundefinedtype);
              include(generictype.symoptions,sp_generic_para);
              result.add(generictype);
            end;
          consume(_ID);
        until not try_to_consume(_COMMA) ;
      end;


    procedure insert_generic_parameter_types(def:tstoreddef;genericdef:tstoreddef;genericlist:TFPObjectList);
      var
        i: longint;
        generictype: ttypesym;
        st: tsymtable;
      begin
        def.genericdef:=genericdef;
        if not assigned(genericlist) then
          exit;

        case def.typ of
          recorddef,objectdef: st:=tabstractrecorddef(def).symtable;
          arraydef: st:=tarraydef(def).symtable;
          procvardef,procdef: st:=tabstractprocdef(def).parast;
          else
            internalerror(201101020);
        end;

        for i:=0 to genericlist.count-1 do
          begin
            generictype:=ttypesym(genericlist[i]);
            if generictype.typedef.typ=undefineddef then
              include(def.defoptions,df_generic)
            else
              include(def.defoptions,df_specialization);
            st.insert(generictype);
          end;
       end;

end.
