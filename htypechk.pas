{
    Copyright (c) 1998-2002 by Florian Klaempfl

    This unit exports some help routines for the type checking

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
unit htypechk;

{$i fpcdefs.inc}

interface

    uses
      cclasses,tokens,cpuinfo,
      node,globtype,
      symconst,symtype,symdef,symsym,symbase;

    type
      Ttok2nodeRec=record
        tok : ttoken;
        nod : tnodetype;
        inr : integer; // inline number
        op_overloading_supported : boolean;
      end;

      pcandidate = ^tcandidate;
      tcandidate = record
         next         : pcandidate;
         data         : tprocdef;
         wrongparaidx,
         firstparaidx : integer;
         exact_count,
         equal_count,
         cl1_count,
         cl2_count,
         cl3_count,
         cl4_count,
         cl5_count,
         coper_count : integer; { should be signed }
         ordinal_distance : double;
         invalid     : boolean;
         wrongparanr : byte;
      end;

      tcallcandidates = class
      private
        FProcsym     : tprocsym;
        FProcsymtable : tsymtable;
        FOperator    : ttoken;
        FCandidateProcs    : pcandidate;
        FProcCnt    : integer;
        FParaNode   : tnode;
        FParaLength : smallint;
        FAllowVariant : boolean;
        procedure collect_overloads_in_struct(structdef:tabstractrecorddef;ProcdefOverloadList:TFPObjectList;searchhelpers,anoninherited:boolean);
        procedure collect_overloads_in_units(ProcdefOverloadList:TFPObjectList; objcidcall,explicitunit: boolean);
        procedure create_candidate_list(ignorevisibility,allowdefaultparas,objcidcall,explicitunit,searchhelpers,anoninherited:boolean);
        function  proc_add(st:tsymtable;pd:tprocdef;objcidcall: boolean):pcandidate;
      public
        constructor create(sym:tprocsym;st:TSymtable;ppn:tnode;ignorevisibility,allowdefaultparas,objcidcall,explicitunit,searchhelpers,anoninherited:boolean);
        constructor create_operator(op:ttoken;ppn:tnode);
        destructor destroy;override;
        procedure list(all:boolean);
{$ifdef EXTDEBUG}
        procedure dump_info(lvl:longint);
{$endif EXTDEBUG}
        procedure get_information;
        function  choose_best(var bestpd:tabstractprocdef; singlevariant: boolean):integer;
        procedure find_wrong_para;
        property  Count:integer read FProcCnt;
      end;

    type
      tregableinfoflag = (
         // can be put in a register if it's the address of a var/out/const parameter
         ra_addr_regable,
         // orthogonal to above flag: the address of the node is taken and may
         // possibly escape the block in which this node is declared (e.g. a
         // local variable is passed as var parameter to another procedure)
         ra_addr_taken);
      tregableinfoflags = set of tregableinfoflag;

  {$i compinnr.inc}
    const
      tok2nodes=27;
      tok2node:array[1..tok2nodes] of ttok2noderec=(
        (tok:_PLUS       ;nod:addn;inr:-1;op_overloading_supported:true),      { binary overloading supported }
        (tok:_MINUS      ;nod:subn;inr:-1;op_overloading_supported:true),      { binary and unary overloading supported }
        (tok:_STAR       ;nod:muln;inr:-1;op_overloading_supported:true),      { binary overloading supported }
        (tok:_SLASH      ;nod:slashn;inr:-1;op_overloading_supported:true),    { binary overloading supported }
        (tok:_EQ         ;nod:equaln;inr:-1;op_overloading_supported:true),    { binary overloading supported }
        (tok:_GT         ;nod:gtn;inr:-1;op_overloading_supported:true),       { binary overloading supported }
        (tok:_LT         ;nod:ltn;inr:-1;op_overloading_supported:true),       { binary overloading supported }
        (tok:_GTE        ;nod:gten;inr:-1;op_overloading_supported:true),      { binary overloading supported }
        (tok:_LTE        ;nod:lten;inr:-1;op_overloading_supported:true),      { binary overloading supported }
        (tok:_SYMDIF     ;nod:symdifn;inr:-1;op_overloading_supported:true),   { binary overloading supported }
        (tok:_STARSTAR   ;nod:starstarn;inr:-1;op_overloading_supported:true), { binary overloading supported }
        (tok:_OP_AS      ;nod:asn;inr:-1;op_overloading_supported:false),      { binary overloading NOT supported }
        (tok:_OP_IN      ;nod:inn;inr:-1;op_overloading_supported:true),       { binary overloading supported }
        (tok:_OP_IS      ;nod:isn;inr:-1;op_overloading_supported:false),      { binary overloading NOT supported }
        (tok:_OP_OR      ;nod:orn;inr:-1;op_overloading_supported:true),       { binary overloading supported }
        (tok:_OP_AND     ;nod:andn;inr:-1;op_overloading_supported:true),      { binary overloading supported }
        (tok:_OP_DIV     ;nod:divn;inr:-1;op_overloading_supported:true),      { binary overloading supported }
        (tok:_OP_NOT     ;nod:notn;inr:-1;op_overloading_supported:true),      { unary overloading supported }
        (tok:_OP_MOD     ;nod:modn;inr:-1;op_overloading_supported:true),      { binary overloading supported }
        (tok:_OP_SHL     ;nod:shln;inr:-1;op_overloading_supported:true),      { binary overloading supported }
        (tok:_OP_SHR     ;nod:shrn;inr:-1;op_overloading_supported:true),      { binary overloading supported }
        (tok:_OP_XOR     ;nod:xorn;inr:-1;op_overloading_supported:true),      { binary overloading supported }
        (tok:_ASSIGNMENT ;nod:assignn;inr:-1;op_overloading_supported:true),   { unary overloading supported }
        (tok:_OP_EXPLICIT;nod:assignn;inr:-1;op_overloading_supported:true),   { unary overloading supported }
        (tok:_NE         ;nod:unequaln;inr:-1;op_overloading_supported:true),  { binary overloading supported }
        (tok:_OP_INC     ;nod:inlinen;inr:in_inc_x;op_overloading_supported:true),{ unary overloading supported }
        (tok:_OP_DEC     ;nod:inlinen;inr:in_dec_x;op_overloading_supported:true) { unary overloading supported }
      );

      { true, if we are parsing stuff which allows array constructors }
      allow_array_constructor : boolean = false;

    function node2opstr(nt:tnodetype):string;

    { check operator args and result type }
    function isbinaryoperatoroverloadable(treetyp:tnodetype;ld:tdef;lt:tnodetype;rd:tdef;rt:tnodetype) : boolean;
    function isoperatoracceptable(pf : tprocdef; optoken : ttoken) : boolean;
    function isunaryoverloaded(var t : tnode) : boolean;
    function isbinaryoverloaded(var t : tnode) : boolean;

    { Register Allocation }
    procedure make_not_regable(p : tnode; how: tregableinfoflags);

    { procvar handling }
    function  is_proc2procvar_load(p:tnode;out realprocdef:tprocdef):boolean;
    { returns whether a node represents a load of the function result node via
      the function name (so it could also be a recursive call to the function
      in case there or no parameters, or the function could be passed as
      procvar }
    function  is_ambiguous_funcret_load(p: tnode; out owningprocdef: tprocdef): boolean;
    procedure test_local_to_procvar(from_def:tprocvardef;to_def:tdef);

    { sets varsym varstate field correctly }
    type
      tvarstateflag = (vsf_must_be_valid,vsf_use_hints);
      tvarstateflags = set of tvarstateflag;
    procedure set_varstate(p:tnode;newstate:tvarstate;varstateflags:tvarstateflags);

    { sets the callunique flag, if the node is a vecn, }
    { takes care of type casts etc.                 }
    procedure set_unique(p : tnode);

    function  valid_for_formal_var(p : tnode; report_errors: boolean) : boolean;
    function  valid_for_formal_const(p : tnode; report_errors: boolean) : boolean;
    function  valid_for_var(p:tnode; report_errors: boolean):boolean;
    function  valid_for_assignment(p:tnode; report_errors: boolean):boolean;
    function  valid_for_loopvar(p:tnode; report_errors: boolean):boolean;
    function  valid_for_addr(p : tnode; report_errors: boolean) : boolean;

    function allowenumop(nt:tnodetype):boolean;

    procedure check_hints(const srsym: tsym; const symoptions: tsymoptions; const deprecatedmsg : pshortstring);

    procedure check_ranges(const location: tfileposinfo; source: tnode; destdef: tdef);

implementation

    uses
       sysutils,
       systems,constexp,globals,
       cutils,verbose,
       symtable,
       defutil,defcmp,
       nbas,ncnv,nld,nmem,ncal,nmat,ninl,nutils,ncon,
       cgbase,procinfo
       ;

    type
      TValidAssign=(Valid_Property,Valid_Void,Valid_Const,Valid_Addr,Valid_Packed);
      TValidAssigns=set of TValidAssign;


    function node2opstr(nt:tnodetype):string;
      var
        i : integer;
      begin
        result:='<unknown>';
        for i:=1 to tok2nodes do
          if tok2node[i].nod=nt then
            begin
              result:=tokeninfo^[tok2node[i].tok].str;
              break;
            end;
       end;


    function isbinaryoperatoroverloadable(treetyp:tnodetype;ld:tdef;lt:tnodetype;rd:tdef;rt:tnodetype) : boolean;

        function internal_check(treetyp:tnodetype;ld:tdef;lt:tnodetype;rd:tdef;rt:tnodetype;var allowed:boolean):boolean;
        begin
          internal_check:=true;
          case ld.typ of
            formaldef,
            recorddef,
            variantdef :
              begin
                allowed:=true;
              end;
            procvardef :
              begin
                if (rd.typ in [pointerdef,procdef,procvardef]) then
                 begin
                   allowed:=false;
                   exit;
                 end;
                allowed:=true;
              end;
            pointerdef :
              begin
                if ((rd.typ in [orddef,enumdef,pointerdef,classrefdef,procvardef]) or
                    is_implicit_pointer_object_type(rd)) then
                 begin
                   allowed:=false;
                   exit;
                 end;

                { don't allow pchar+string }
                if (is_pchar(ld) or is_pwidechar(ld)) and
                   ((rd.typ=stringdef) or
                    is_pchar(rd) or
                    is_pwidechar(rd) or
                    is_chararray(rd) or
                    is_widechararray(rd)) then
                 begin
                   allowed:=false;
                   exit;
                 end;
                allowed:=true;
              end;
            arraydef :
              begin
                { not vector/mmx }
                if ((cs_mmx in current_settings.localswitches) and
                   is_mmx_able_array(ld)) or
                   ((cs_support_vectors in current_settings.globalswitches) and
                   is_vector(ld)) then
                 begin
                   allowed:=false;
                   exit;
                 end;
                { not chararray+[(wide)char,(wide)string,(wide)chararray] }
                if (is_chararray(ld) or is_widechararray(ld) or
                    is_open_chararray(ld) or is_open_widechararray(ld))
                   and
                   ((rd.typ in [stringdef,orddef,enumdef]) or
                    is_pchar(rd) or
                    is_pwidechar(rd) or
                    is_chararray(rd) or
                    is_widechararray(rd) or
                    is_open_chararray(rd) or
                    is_open_widechararray(rd) or
                    (rt=niln)) then
                 begin
                   allowed:=false;
                   exit;
                 end;
                { dynamic array compare with niln }
                if ((is_dynamic_array(ld) and
                   (rt=niln)) or
                   (is_dynamic_array(ld) and is_dynamic_array(rd)))
                   and
                   (treetyp in [equaln,unequaln]) then
                 begin
                   allowed:=false;
                   exit;
                 end;
                allowed:=true;
              end;
            objectdef :
              begin
                { <> and = are defined for implicit pointer object types }
                if (treetyp in [equaln,unequaln]) and
                   is_implicit_pointer_object_type(ld) then
                 begin
                   allowed:=false;
                   exit;
                 end;
                allowed:=true;
              end;
            stringdef :
              begin
                if (rd.typ in [orddef,enumdef,stringdef]) or
                   is_pchar(rd) or
                   is_pwidechar(rd) or
                   is_chararray(rd) or
                   is_widechararray(rd) or
                   is_open_chararray(rd) or
                   is_open_widechararray(rd) then
                 begin
                   allowed:=false;
                   exit;
                 end;
                allowed:=true;
              end;
            else
              internal_check:=false;
          end;
        end;

      var
        allowed : boolean;
      begin
        { power ** is always possible }
        if (treetyp=starstarn) then
         begin
           isbinaryoperatoroverloadable:=true;
           exit;
         end;
        { order of arguments does not matter so we have to check also
          the reversed order }
        allowed:=false;
        if not internal_check(treetyp,ld,lt,rd,rt,allowed) then
          internal_check(treetyp,rd,rt,ld,lt,allowed);
        isbinaryoperatoroverloadable:=allowed;
      end;


    function isunaryoperatoroverloadable(treetyp:tnodetype;inlinenumber:integer;ld:tdef) : boolean;
      begin
        result:=false;
        case treetyp of
          subn,
          addn,
          unaryminusn,
          unaryplusn,
          inlinen:
            begin
              { only Inc, Dec inline functions are supported for now, so skip check inlinenumber }

              if (ld.typ in [orddef,enumdef,floatdef]) then
                exit;

{$ifdef SUPPORT_MMX}
              if (cs_mmx in current_settings.localswitches) and
                 is_mmx_able_array(ld) then
                exit;
{$endif SUPPORT_MMX}

              result:=true;
            end;

          notn :
            begin
              if (ld.typ in [orddef,enumdef,floatdef]) then
                exit;

{$ifdef SUPPORT_MMX}
              if (cs_mmx in current_settings.localswitches) and
                 is_mmx_able_array(ld) then
                exit;
{$endif SUPPORT_MMX}

              result:=true;
            end;
        end;
      end;


    function isoperatoracceptable(pf : tprocdef; optoken : ttoken) : boolean;
      var
        ld,rd : tdef;
        i : longint;
        eq : tequaltype;
        conv : tconverttype;
        pd : tprocdef;
        oldcount,
        count: longint;
        parasym : tparavarsym;
      begin
        result:=false;
        count := pf.parast.SymList.count;

        oldcount:=count;
        while count > 0 do
          begin
            parasym:=tparavarsym(pf.parast.SymList[count-1]);
            if is_boolean(parasym.vardef) then
              begin
                if parasym.name='RANGECHECK' then
                  begin
                    Include(parasym.varoptions, vo_is_hidden_para);
                    Include(parasym.varoptions, vo_is_range_check);
                    Dec(count);
                  end
                else if parasym.name='OVERFLOWCHECK' then
                  begin
                    Include(parasym.varoptions, vo_is_hidden_para);
                    Include(parasym.varoptions, vo_is_overflow_check);
                    Dec(count);
                  end
                else
                  break;
              end
            else
              break;
          end;
        if count<>oldcount then
          pf.calcparas;

        case count of
          1 : begin
                ld:=tparavarsym(pf.parast.SymList[0]).vardef;
                { assignment is a special case }
                if optoken in [_ASSIGNMENT,_OP_EXPLICIT] then
                  begin
                    eq:=compare_defs_ext(ld,pf.returndef,nothingn,conv,pd,[cdo_explicit]);
                    result:=
                      (eq=te_exact) or
                      (
                        (eq=te_incompatible) and
                        { don't allow overloading assigning to custom shortstring
                          types, because we also don't want to differentiate based
                          on different shortstring types (e.g.,
                          "operator :=(const v: variant) res: shorstring" also
                          has to work for assigning a variant to a string[80])
                        }
                        (not is_shortstring(pf.returndef) or
                         (tstringdef(pf.returndef).len=255))
                      );
                  end
                else
                { enumerator is a special case too }
                if optoken=_OP_ENUMERATOR then
                  begin
                    result:=
                      is_class_or_interface_or_object(pf.returndef) or
                      is_record(pf.returndef);
                    if result then
                      begin
                        if not assigned(tabstractrecorddef(pf.returndef).search_enumerator_move) then
                          begin
                            Message1(sym_e_no_enumerator_move, pf.returndef.typename);
                            result:=false;
                          end;
                        if not assigned(tabstractrecorddef(pf.returndef).search_enumerator_current) then
                          begin
                            Message1(sym_e_no_enumerator_current,pf.returndef.typename);
                            result:=false;
                          end;
                      end;
                  end
                else
                  begin
                    for i:=1 to tok2nodes do
                      if tok2node[i].tok=optoken then
                        begin
                          result:=
                            tok2node[i].op_overloading_supported and
                            isunaryoperatoroverloadable(tok2node[i].nod,tok2node[i].inr,ld);
                          break;
                        end;
                    { Inc, Dec operators are valid if only result type is the same as argument type }
                    if result and (optoken in [_OP_INC,_OP_DEC]) then
                      result:=pf.returndef=ld;
                  end;
              end;
          2 : begin
                for i:=1 to tok2nodes do
                  if tok2node[i].tok=optoken then
                    begin
                      ld:=tparavarsym(pf.parast.SymList[0]).vardef;
                      rd:=tparavarsym(pf.parast.SymList[1]).vardef;
                      result:=
                        tok2node[i].op_overloading_supported and
                        isbinaryoperatoroverloadable(tok2node[i].nod,ld,nothingn,rd,nothingn);
                      break;
                    end;
              end;
        end;
      end;


    function isunaryoverloaded(var t : tnode) : boolean;
      var
        ld      : tdef;
        optoken : ttoken;
        operpd  : tprocdef;
        ppn     : tcallparanode;
        candidates : tcallcandidates;
        cand_cnt,
        inlinenumber: integer;
      begin
        result:=false;
        operpd:=nil;

        { load easier access variables }
        ld:=tunarynode(t).left.resultdef;

        { if we are dealing with inline function then get the function }
        if t.nodetype=inlinen then
          inlinenumber:=tinlinenode(t).inlinenumber
        else
          inlinenumber:=-1;

        if not isunaryoperatoroverloadable(t.nodetype,inlinenumber,ld) then
          exit;

        { operator overload is possible }
        result:=true;

        optoken:=NOTOKEN;
        case t.nodetype of
           notn:
             optoken:=_OP_NOT;
           unaryminusn:
             optoken:=_MINUS;
           unaryplusn:
             optoken:=_PLUS;
           inlinen:
             case inlinenumber of
                in_inc_x:
                  optoken:=_OP_INC;
                in_dec_x:
                  optoken:=_OP_DEC;
             end;
        end;
        if (optoken=NOTOKEN) then
          begin
            CGMessage(parser_e_operator_not_overloaded);
            t:=cnothingnode.create;
            exit;
          end;

        { generate parameter nodes }
        { for inline nodes just copy existent callparanode }
        if (t.nodetype=inlinen) and (tinlinenode(t).left.nodetype=callparan) then
          ppn:=tcallparanode(tinlinenode(t).left.getcopy)
        else
          begin
            ppn:=ccallparanode.create(tunarynode(t).left.getcopy,nil);
            ppn.get_paratype;
          end;
        candidates:=tcallcandidates.create_operator(optoken,ppn);

        { stop when there are no operators found }
        if candidates.count=0 then
          begin
            CGMessage2(parser_e_operator_not_overloaded_2,ld.typename,arraytokeninfo[optoken].str);
            candidates.free;
            ppn.free;
            t:=cnothingnode.create;
            exit;
          end;

        { Retrieve information about the candidates }
        candidates.get_information;
{$ifdef EXTDEBUG}
        { Display info when multiple candidates are found }
        candidates.dump_info(V_Debug);
{$endif EXTDEBUG}
        cand_cnt:=candidates.choose_best(tabstractprocdef(operpd),false);

        { exit when no overloads are found }
        if cand_cnt=0 then
          begin
            CGMessage2(parser_e_operator_not_overloaded_2,ld.typename,arraytokeninfo[optoken].str);
            candidates.free;
            ppn.free;
            t:=cnothingnode.create;
            exit;
          end;

        { Multiple candidates left? }
        if cand_cnt>1 then
          begin
            CGMessage(type_e_cant_choose_overload_function);
{$ifdef EXTDEBUG}
            candidates.dump_info(V_Hint);
{$else EXTDEBUG}
            candidates.list(false);
{$endif EXTDEBUG}
            { we'll just use the first candidate to make the
              call }
          end;
        candidates.free;

        addsymref(operpd.procsym);

        { the nil as symtable signs firstcalln that this is
          an overloaded operator }
        t:=ccallnode.create(ppn,Tprocsym(operpd.procsym),nil,nil,[]);

        { we already know the procdef to use, so it can
          skip the overload choosing in callnode.pass_typecheck }
        tcallnode(t).procdefinition:=operpd;
      end;


    function isbinaryoverloaded(var t : tnode) : boolean;
      var
        rd,ld   : tdef;
        optoken : ttoken;
        operpd  : tprocdef;
        ht      : tnode;
        ppn     : tcallparanode;
        cand_cnt : integer;

        function search_operator(optoken:ttoken;generror:boolean): integer;
          var
            candidates : tcallcandidates;
          begin
            { generate parameter nodes }
            ppn:=ccallparanode.create(tbinarynode(t).right.getcopy,ccallparanode.create(tbinarynode(t).left.getcopy,nil));
            ppn.get_paratype;
            candidates:=tcallcandidates.create_operator(optoken,ppn);

            { for commutative operators we can swap arguments and try again }
            if (candidates.count=0) and
               not(optoken in [_OP_SHL,_OP_SHR,_OP_DIV,_OP_MOD,_STARSTAR,_SLASH,_MINUS]) then
              begin
                candidates.free;
                reverseparameters(ppn);
                { reverse compare operators }
                case optoken of
                  _LT:
                    optoken:=_GTE;
                  _GT:
                    optoken:=_LTE;
                  _LTE:
                    optoken:=_GT;
                  _GTE:
                    optoken:=_LT;
                end;
                candidates:=tcallcandidates.create_operator(optoken,ppn);
              end;

            { stop when there are no operators found }
            result:=candidates.count;
            if (result=0) and generror then
              begin
                CGMessage(parser_e_operator_not_overloaded);
                candidates.free;
                exit;
              end;

            if (result>0) then
              begin
                { Retrieve information about the candidates }
                candidates.get_information;
        {$ifdef EXTDEBUG}
                { Display info when multiple candidates are found }
                candidates.dump_info(V_Debug);
        {$endif EXTDEBUG}
                result:=candidates.choose_best(tabstractprocdef(operpd),false);
              end;

            { exit when no overloads are found }
            if (result=0) and generror then
              begin
                CGMessage3(parser_e_operator_not_overloaded_3,ld.typename,arraytokeninfo[optoken].str,rd.typename);
                candidates.free;
                exit;
              end;

            { Multiple candidates left? }
            if result>1 then
              begin
                CGMessage(type_e_cant_choose_overload_function);
    {$ifdef EXTDEBUG}
                candidates.dump_info(V_Hint);
    {$else EXTDEBUG}
                candidates.list(false);
    {$endif EXTDEBUG}
                { we'll just use the first candidate to make the
                  call }
              end;
            candidates.free;
          end;

      begin
        isbinaryoverloaded:=false;
        operpd:=nil;
        { load easier access variables }
        ld:=tbinarynode(t).left.resultdef;
        rd:=tbinarynode(t).right.resultdef;
        if not isbinaryoperatoroverloadable(t.nodetype,ld,tbinarynode(t).left.nodetype,rd,tbinarynode(t).right.nodetype) then
          exit;

        { operator overload is possible }
        result:=true;

        case t.nodetype of
           equaln:
             optoken:=_EQ;
           unequaln:
             optoken:=_NE;
           addn:
             optoken:=_PLUS;
           subn:
             optoken:=_MINUS;
           muln:
             optoken:=_STAR;
           starstarn:
             optoken:=_STARSTAR;
           slashn:
             optoken:=_SLASH;
           ltn:
             optoken:=_LT;
           gtn:
             optoken:=_GT;
           lten:
             optoken:=_LTE;
           gten:
             optoken:=_GTE;
           symdifn :
             optoken:=_SYMDIF;
           modn :
             optoken:=_OP_MOD;
           orn :
             optoken:=_OP_OR;
           xorn :
             optoken:=_OP_XOR;
           andn :
             optoken:=_OP_AND;
           divn :
             optoken:=_OP_DIV;
           shln :
             optoken:=_OP_SHL;
           shrn :
             optoken:=_OP_SHR;
           inn :
             optoken:=_OP_IN;
           else
             begin
               CGMessage(parser_e_operator_not_overloaded);
               t:=cnothingnode.create;
               exit;
             end;
        end;

        cand_cnt:=search_operator(optoken,optoken<>_NE);

        { no operator found for "<>" then search for "=" operator }
        if (cand_cnt=0) and (optoken=_NE) then
          begin
            ppn.free;
            operpd:=nil;
            optoken:=_EQ;
            cand_cnt:=search_operator(optoken,true);
          end;

        if (cand_cnt=0) then
          begin
            ppn.free;
            t:=cnothingnode.create;
            exit;
          end;

        addsymref(operpd.procsym);

        { the nil as symtable signs firstcalln that this is
          an overloaded operator }
        ht:=ccallnode.create(ppn,Tprocsym(operpd.procsym),nil,nil,[]);

        { we already know the procdef to use, so it can
          skip the overload choosing in callnode.pass_typecheck }
        tcallnode(ht).procdefinition:=operpd;

        { if we found "=" operator for "<>" expression then use it
          together with "not" }
        if (t.nodetype=unequaln) and (optoken=_EQ) then
          ht:=cnotnode.create(ht);
        t:=ht;
      end;


{****************************************************************************
                          Register Calculation
****************************************************************************}

    { marks an lvalue as "unregable" }
    procedure make_not_regable_intern(p : tnode; how: tregableinfoflags; records_only: boolean);
      begin
        repeat
          case p.nodetype of
            subscriptn:
              begin
                records_only:=true;
                p:=tsubscriptnode(p).left;
              end;
            vecn:
              begin
                { if there's an implicit dereference, we can stop (just like
                  when there is an actual derefn) }
                if ((tvecnode(p).left.resultdef.typ=arraydef) and
                    not is_special_array(tvecnode(p).left.resultdef)) or
                   ((tvecnode(p).left.resultdef.typ=stringdef) and
                    (tstringdef(tvecnode(p).left.resultdef).stringtype in [st_shortstring,st_longstring])) then
                  p:=tvecnode(p).left
                else
                  break;
              end;
            typeconvn :
               begin
                 { implicit dereference -> stop }
                 if (ttypeconvnode(p).convtype=tc_pointer_2_array) then
                   break;
                 if (ttypeconvnode(p).resultdef.typ=recorddef) then
                   records_only:=false;
                 p:=ttypeconvnode(p).left;
               end;
            loadn :
              begin
                if (tloadnode(p).symtableentry.typ in [staticvarsym,localvarsym,paravarsym]) then
                  begin
                    if (ra_addr_taken in how) then
                      tabstractvarsym(tloadnode(p).symtableentry).addr_taken:=true;
                    if (tabstractvarsym(tloadnode(p).symtableentry).varregable <> vr_none) and
                       ((not records_only) or
                        (tabstractvarsym(tloadnode(p).symtableentry).vardef.typ = recorddef)) then
                      if (tloadnode(p).symtableentry.typ = paravarsym) and
                         (ra_addr_regable in how) then
                        tabstractvarsym(tloadnode(p).symtableentry).varregable:=vr_addr
                      else
                        tabstractvarsym(tloadnode(p).symtableentry).varregable:=vr_none;
                  end;
                break;
              end;
            temprefn :
              begin
                if (ra_addr_taken in how) then
                  include(ttemprefnode(p).tempinfo^.flags,ti_addr_taken);
                if (ti_may_be_in_reg in ttemprefnode(p).tempinfo^.flags) and
                   ((not records_only) or
                    (ttemprefnode(p).tempinfo^.typedef.typ = recorddef)) then
                  exclude(ttemprefnode(p).tempinfo^.flags,ti_may_be_in_reg);
                break;
              end;
            else
              break;
          end;
        until false;
      end;

    procedure make_not_regable(p : tnode; how: tregableinfoflags);
      begin
        make_not_regable_intern(p,how,false);
      end;


{****************************************************************************
                          Subroutine Handling
****************************************************************************}

    function is_proc2procvar_load(p:tnode;out realprocdef:tprocdef):boolean;
      begin
        result:=false;
        { remove voidpointer typecast for tp procvars }
        if ((m_tp_procvar in current_settings.modeswitches) or
            (m_mac_procvar in current_settings.modeswitches)) and
           (p.nodetype=typeconvn) and
           is_voidpointer(p.resultdef) then
          p:=tunarynode(p).left;
        result:=(p.nodetype=typeconvn) and
                (ttypeconvnode(p).convtype=tc_proc_2_procvar);
        if result then
          realprocdef:=tprocdef(ttypeconvnode(p).left.resultdef);
      end;


    function is_ambiguous_funcret_load(p: tnode; out owningprocdef: tprocdef): boolean;
      begin
        result:=false;
        { the funcret is an absolutevarsym, which gets converted into a type
          conversion node of the loadnode of the actual function result. Its
          resulttype is obviously the same as that of the real function result }
        if (p.nodetype=typeconvn) and
              (p.resultdef=ttypeconvnode(p).left.resultdef) then
          p:=ttypeconvnode(p).left;
        if (p.nodetype=loadn) and
           (tloadnode(p).symtableentry.typ in [absolutevarsym,localvarsym,paravarsym]) and
           ([vo_is_funcret,vo_is_result] * tabstractvarsym(tloadnode(p).symtableentry).varoptions = [vo_is_funcret]) then
         begin
           owningprocdef:=tprocdef(tloadnode(p).symtableentry.owner.defowner);
           result:=true;
         end;
      end;


    { local routines can't be assigned to procvars }
    procedure test_local_to_procvar(from_def:tprocvardef;to_def:tdef);
      begin
         if not(m_nested_procvars in current_settings.modeswitches) and
            (from_def.parast.symtablelevel>normal_function_level) and
            (to_def.typ=procvardef) then
           CGMessage(type_e_cannot_local_proc_to_procvar);
      end;


    procedure set_varstate(p:tnode;newstate:tvarstate;varstateflags:tvarstateflags);
      const
        vstrans: array[tvarstate,tvarstate] of tvarstate = (
          { vs_none -> ... }
          (vs_none,vs_declared,vs_initialised,vs_read,vs_read_not_warned,vs_referred_not_inited,vs_written,vs_readwritten),
          { vs_declared -> ... }
          (vs_none,vs_declared,vs_initialised,vs_read,vs_read_not_warned,vs_referred_not_inited,vs_written,vs_readwritten),
          { vs_initialised -> ... }
          (vs_none,vs_initialised,vs_initialised,vs_read,vs_read,vs_read,vs_written,vs_readwritten),
          { vs_read -> ... }
          (vs_none,vs_read,vs_read,vs_read,vs_read,vs_read,vs_readwritten,vs_readwritten),
          { vs_read_not_warned -> ... }
          (vs_none,vs_read_not_warned,vs_read,vs_read,vs_read_not_warned,vs_read_not_warned,vs_readwritten,vs_readwritten),
          { vs_referred_not_inited }
          (vs_none,vs_referred_not_inited,vs_read,vs_read,vs_read_not_warned,vs_referred_not_inited,vs_written,vs_readwritten),
          { vs_written -> ... }
          (vs_none,vs_written,vs_written,vs_readwritten,vs_readwritten,vs_written,vs_written,vs_readwritten),
          { vs_readwritten -> ... }
          (vs_none,vs_readwritten,vs_readwritten,vs_readwritten,vs_readwritten,vs_readwritten,vs_readwritten,vs_readwritten));
      var
        hsym : tabstractvarsym;
      begin
        { make sure we can still warn about uninitialised use after high(v), @v etc }
        if (newstate = vs_read) and
           not(vsf_must_be_valid in varstateflags) then
          newstate := vs_referred_not_inited;

        while assigned(p) do
         begin
           case p.nodetype of
             derefn:
               begin
                 if (tderefnode(p).left.nodetype=temprefn) and
                    assigned(ttemprefnode(tderefnode(p).left).tempinfo^.withnode) then
                   p:=ttemprefnode(tderefnode(p).left).tempinfo^.withnode
                 else
                   break;
               end;
             typeconvn :
               begin
                 case ttypeconvnode(p).convtype of
                   tc_cchar_2_pchar,
                   tc_cstring_2_pchar,
                   tc_array_2_pointer :
                     exclude(varstateflags,vsf_must_be_valid);
                   tc_pchar_2_string,
                   tc_pointer_2_array :
                     include(varstateflags,vsf_must_be_valid);
                 end;
                 p:=tunarynode(p).left;
               end;
             subscriptn :
               begin
                 if is_implicit_pointer_object_type(tunarynode(p).left.resultdef) then
                   newstate := vs_read;
                 p:=tunarynode(p).left;
               end;
             vecn:
               begin
                 set_varstate(tbinarynode(p).right,vs_read,[vsf_must_be_valid]);
                 if (newstate in [vs_read,vs_readwritten]) or
                    not(tunarynode(p).left.resultdef.typ in [stringdef,arraydef]) then
                   include(varstateflags,vsf_must_be_valid)
                 else if (newstate = vs_written) then
                   exclude(varstateflags,vsf_must_be_valid);
                 p:=tunarynode(p).left;
               end;
             { do not parse calln }
             calln :
               break;
             loadn :
               begin
                 if (tloadnode(p).symtableentry.typ in [localvarsym,paravarsym,staticvarsym]) then
                   begin
                     hsym:=tabstractvarsym(tloadnode(p).symtableentry);
                     if (vsf_must_be_valid in varstateflags) and
                        (hsym.varstate in [vs_declared,vs_read_not_warned,vs_referred_not_inited]) then
                       begin
                         { Give warning/note for uninitialized locals }
                         if assigned(hsym.owner) and
                           not(cs_opt_nodedfa in current_settings.optimizerswitches) and
                            not(vo_is_external in hsym.varoptions) and
                            (hsym.owner.symtabletype in [parasymtable,localsymtable,staticsymtable]) and
                            ((hsym.owner=current_procinfo.procdef.localst) or
                             (hsym.owner=current_procinfo.procdef.parast)) then
                           begin
                             if (vo_is_funcret in hsym.varoptions) then
                               begin
                                 if (vsf_use_hints in varstateflags) then
                                   CGMessagePos(p.fileinfo,sym_h_function_result_uninitialized)
                                 else
                                   CGMessagePos(p.fileinfo,sym_w_function_result_uninitialized)
                               end
                             else
                               begin
                                 if tloadnode(p).symtable.symtabletype=localsymtable then
                                   begin
                                     if (vsf_use_hints in varstateflags) then
                                       CGMessagePos1(p.fileinfo,sym_h_uninitialized_local_variable,hsym.realname)
                                     else
                                       CGMessagePos1(p.fileinfo,sym_w_uninitialized_local_variable,hsym.realname);
                                   end
                                 else
                                   begin
                                     if (vsf_use_hints in varstateflags) then
                                       CGMessagePos1(p.fileinfo,sym_h_uninitialized_variable,hsym.realname)
                                     else
                                       CGMessagePos1(p.fileinfo,sym_w_uninitialized_variable,hsym.realname);
                                   end;
                               end;
                           end
                         else if (newstate = vs_read) then
                           newstate := vs_read_not_warned;
                       end;
                     hsym.varstate := vstrans[hsym.varstate,newstate];
                   end;
                 case newstate of
                   vs_written:
                     include(tloadnode(p).flags,nf_write);
                   vs_readwritten:
                     if not(nf_write in tloadnode(p).flags) then
                       include(tloadnode(p).flags,nf_modify);
                 end;
                 break;
               end;
             callparan :
               internalerror(200310081);
             else
               break;
           end;{case }
         end;
      end;


    procedure set_unique(p : tnode);
      begin
        while assigned(p) do
         begin
           case p.nodetype of
             vecn:
               begin
                 include(p.flags,nf_callunique);
                 break;
               end;
             typeconvn,
             subscriptn,
             derefn:
               p:=tunarynode(p).left;
             else
               break;
           end;
         end;
      end;


    function  valid_for_assign(p:tnode;opts:TValidAssigns; report_errors: boolean):boolean;
      var
        hp2,
        hp : tnode;
        gotstring,
        gotsubscript,
        gotrecord,
        gotpointer,
        gotvec,
        gotclass,
        gotdynarray,
        gotderef,
        gottypeconv : boolean;
        fromdef,
        todef    : tdef;
        errmsg,
        temp     : longint;
      begin
        if valid_const in opts then
          errmsg:=type_e_variable_id_expected
        else if valid_property in opts then
          errmsg:=type_e_argument_cant_be_assigned
        else
          errmsg:=type_e_no_addr_of_constant;
        result:=false;
        gotsubscript:=false;
        gotvec:=false;
        gotderef:=false;
        gotrecord:=false;
        gotclass:=false;
        gotpointer:=false;
        gotdynarray:=false;
        gotstring:=false;
        gottypeconv:=false;
        hp:=p;
        if not(valid_void in opts) and
           is_void(hp.resultdef) then
         begin
           if report_errors then
             CGMessagePos(hp.fileinfo,errmsg);
           exit;
         end;
        while assigned(hp) do
         begin
           { property allowed? calln has a property check itself }
           if (nf_isproperty in hp.flags) then
             begin
               { check return type }
               case hp.resultdef.typ of
                 pointerdef :
                   gotpointer:=true;
                 objectdef :
                   gotclass:=is_implicit_pointer_object_type(hp.resultdef);
                 recorddef :
                   gotrecord:=true;
                 classrefdef :
                   gotclass:=true;
                 stringdef :
                   gotstring:=true;
               end;
               if (valid_property in opts) then
                 begin
                   { don't allow writing to calls that will create
                     temps like calls that return a structure and we
                     are assigning to a member }
                   if (valid_const in opts) or
                      { if we got a deref, we won't modify the property itself }
                      (gotderef) or
                      { same when we got a class and subscript (= deref) }
                      (gotclass and gotsubscript) or
                      (
                       { allowing assignments to typecasted properties
                           a) is Delphi-incompatible
                           b) causes problems in case the getter is a function
                              (because then the result of the getter is
                               typecasted to this type, and then we "assign" to
                               this typecasted function result) -> always
                               disallow, since property accessors should be
                               transparantly changeable to functions at all
                               times
                       }
                       not(gottypeconv) and
                       not(gotsubscript and gotrecord) and
                       not(gotstring and gotvec)
                      ) then
                     result:=true
                   else
                     if report_errors then
                       CGMessagePos(hp.fileinfo,errmsg);
                 end
               else
                 begin
                   { 1. if it returns a pointer and we've found a deref,
                     2. if it returns a class and a subscription or with is found
                     3. if the address is needed of a field (subscriptn, vecn) }
                   if (gotpointer and gotderef) or
                      (gotstring and gotvec) or
                      (gotclass and gotsubscript) or
                      (
                        (gotvec and gotdynarray)
                      ) or
                      (
                       (Valid_Addr in opts) and
                       (hp.nodetype in [subscriptn,vecn])
                      ) then
                     result:=true
                   else
                     if report_errors then
                       CGMessagePos(hp.fileinfo,errmsg);
                 end;
               exit;
             end;
           case hp.nodetype of
             temprefn :
               begin
                 valid_for_assign := true;
                 exit;
               end;
             derefn :
               begin
                 gotderef:=true;
                 hp:=tderefnode(hp).left;
               end;
             typeconvn :
               begin
                 gottypeconv:=true;
                 { typecast sizes must match, exceptions:
                   - implicit typecast made by absolute
                   - from formaldef
                   - from void
                   - from/to open array
                   - typecast from pointer to array }
                 fromdef:=ttypeconvnode(hp).left.resultdef;
                 todef:=hp.resultdef;
                 if not((nf_absolute in ttypeconvnode(hp).flags) or
                        (fromdef.typ=formaldef) or
                        is_void(fromdef) or
                        is_open_array(fromdef) or
                        is_open_array(todef) or
                        ((fromdef.typ=pointerdef) and (todef.typ=arraydef)) or
                        ((fromdef.typ = objectdef) and (todef.typ = objectdef) and
                         (tobjectdef(fromdef).is_related(tobjectdef(todef))))) and
                    (fromdef.size<>todef.size) then
                  begin
                    { in TP it is allowed to typecast to smaller types. But the variable can't
                      be in a register }
                    if (m_tp7 in current_settings.modeswitches) or
                       (todef.size<fromdef.size) then
                      make_not_regable(hp,[ra_addr_regable])
                    else
                      if report_errors then
                        CGMessagePos2(hp.fileinfo,type_e_typecast_wrong_size_for_assignment,tostr(fromdef.size),tostr(todef.size));
                  end;

                 { don't allow assignments to typeconvs that need special code }
                 if not(gotsubscript or gotvec or gotderef) and
                    not(ttypeconvnode(hp).assign_allowed) then
                   begin
                     if report_errors then
                       CGMessagePos(hp.fileinfo,errmsg);
                     exit;
                   end;
                 case hp.resultdef.typ of
                   pointerdef :
                     gotpointer:=true;
                   objectdef :
                     gotclass:=is_implicit_pointer_object_type(hp.resultdef);
                   classrefdef :
                     gotclass:=true;
                   arraydef :
                     begin
                       { pointer -> array conversion is done then we need to see it
                         as a deref, because a ^ is then not required anymore }
                       if (ttypeconvnode(hp).left.resultdef.typ=pointerdef) then
                        gotderef:=true;
                     end;
                 end;
                 hp:=ttypeconvnode(hp).left;
               end;
             vecn :
               begin
                 if { only check for first (= outermost) vec node }
                    not gotvec and
                    not(valid_packed in opts) and
                    (tvecnode(hp).left.resultdef.typ = arraydef) and
                    (ado_IsBitPacked in tarraydef(tvecnode(hp).left.resultdef).arrayoptions) and
                    ((tarraydef(tvecnode(hp).left.resultdef).elepackedbitsize mod 8 <> 0) or
                     (is_ordinal(tarraydef(tvecnode(hp).left.resultdef).elementdef) and
                      not ispowerof2(tarraydef(tvecnode(hp).left.resultdef).elepackedbitsize div 8,temp))) then
                   begin
                     if report_errors then
                       if (valid_property in opts) then
                         CGMessagePos(hp.fileinfo,parser_e_packed_element_no_loop)
                       else
                         CGMessagePos(hp.fileinfo,parser_e_packed_element_no_var_addr);
                     exit;
                   end;
                 gotvec:=true;
                 { accesses to dyn. arrays override read only access in delphi }
                 if (m_delphi in current_settings.modeswitches) and is_dynamic_array(tunarynode(hp).left.resultdef) then
                   gotdynarray:=true;
                 hp:=tunarynode(hp).left;
               end;
             blockn :
               begin
                 hp2:=tblocknode(hp).statements;
                 if assigned(hp2) then
                   begin
                     if hp2.nodetype<>statementn then
                       internalerror(2006110801);
                     while assigned(tstatementnode(hp2).next) do
                       hp2:=tstatementnode(hp2).next;
                     hp:=tstatementnode(hp2).statement;
                   end
                 else
                   begin
                     if report_errors then
                      CGMessagePos(hp.fileinfo,type_e_variable_id_expected);
                     exit;
                   end;
               end;
             asn :
               begin
                 { asn can't be assigned directly, it returns the value in a register instead
                   of reference. }
                 if not(gotsubscript or gotderef or gotvec) then
                   begin
                     if report_errors then
                       CGMessagePos(hp.fileinfo,errmsg);
                     exit;
                   end;
                 hp:=tunarynode(hp).left;
               end;
             subscriptn :
               begin
                 { only check first (= outermost) subscriptn }
                 if not gotsubscript and
                    not(valid_packed in opts) and
                    is_packed_record_or_object(tsubscriptnode(hp).left.resultdef) and
                    ((tsubscriptnode(hp).vs.fieldoffset mod 8 <> 0) or
                     (is_ordinal(tsubscriptnode(hp).resultdef) and
                      not ispowerof2(tsubscriptnode(hp).resultdef.packedbitsize div 8,temp)))  then
                   begin
                     if report_errors then
                       if (valid_property in opts) then
                         CGMessagePos(hp.fileinfo,parser_e_packed_element_no_loop)
                       else
                         CGMessagePos(hp.fileinfo,parser_e_packed_element_no_var_addr);
                     exit;
                   end;
                 gotsubscript:=true;
                 { loop counter? }
                 if not(Valid_Const in opts) and
                    (vo_is_loop_counter in tsubscriptnode(hp).vs.varoptions) then
                   begin
                     if report_errors then
                       CGMessage1(parser_e_illegal_assignment_to_count_var,tsubscriptnode(hp).vs.realname);
                     exit;
                   end;
                 { implicit pointer object types result in dereferencing }
                 hp:=tsubscriptnode(hp).left;
                 if is_implicit_pointer_object_type(hp.resultdef) then
                   gotderef:=true;
               end;
             muln,
             divn,
             andn,
             xorn,
             orn,
             notn,
             subn,
             addn :
               begin
                 { Allow operators on a pointer, or an integer
                   and a pointer typecast and deref has been found }
                 if ((hp.resultdef.typ=pointerdef) or
                     (is_integer(hp.resultdef) and gotpointer)) and
                    gotderef then
                  result:=true
                 else
                 { Temp strings are stored in memory, for compatibility with
                   delphi only }
                   if (m_delphi in current_settings.modeswitches) and
                      ((valid_addr in opts) or
                       (valid_const in opts)) and
                      (hp.resultdef.typ=stringdef) then
                     result:=true
                 else
                  if report_errors then
                   CGMessagePos(hp.fileinfo,type_e_variable_id_expected);
                 exit;
               end;
             niln,
             pointerconstn :
               begin
                 { to support e.g. @tmypointer(0)^.data; see tests/tbs/tb0481 }
                 if gotderef then
                  result:=true
                 else
                  if report_errors then
                   CGMessagePos(hp.fileinfo,type_e_no_assign_to_addr);
                 exit;
               end;
             ordconstn,
             realconstn :
               begin
                 { these constants will be passed by value }
                 if report_errors then
                   CGMessagePos(hp.fileinfo,type_e_variable_id_expected);
                 exit;
               end;
             setconstn,
             stringconstn,
             guidconstn :
               begin
                 { these constants will be passed by reference }
                 if valid_const in opts then
                   result:=true
                 else
                   if report_errors then
                     CGMessagePos(hp.fileinfo,type_e_variable_id_expected);
                 exit;
               end;
             addrn :
               begin
                 if gotderef then
                  result:=true
                 else
                  if report_errors then
                   CGMessagePos(hp.fileinfo,type_e_no_assign_to_addr);
                 exit;
               end;
             calln :
               begin
                 { check return type }
                 case hp.resultdef.typ of
                   arraydef :
                     begin
                       { dynamic arrays are allowed when there is also a
                         vec node }
                       if is_dynamic_array(hp.resultdef) and
                          gotvec then
                        begin
                          gotderef:=true;
                          gotpointer:=true;
                        end;
                     end;
                   pointerdef :
                     gotpointer:=true;
                   objectdef :
                     gotclass:=is_implicit_pointer_object_type(hp.resultdef);
                   recorddef, { handle record like class it needs a subscription }
                   classrefdef :
                     gotclass:=true;
                   stringdef :
                     gotstring:=true;
                 end;
                 { 1. if it returns a pointer and we've found a deref,
                   2. if it returns a class or record and a subscription or with is found
                   3. string is returned }
                 if (gotstring and gotvec) or
                    (gotpointer and gotderef) or
                    (gotclass and gotsubscript) then
                  result:=true
                 else
                 { Temp strings are stored in memory, for compatibility with
                   delphi only }
                   if (m_delphi in current_settings.modeswitches) and
                      (valid_addr in opts) and
                      (hp.resultdef.typ=stringdef) then
                     result:=true
                 else
                   if ([valid_const,valid_addr] * opts = [valid_const]) then
                     result:=true
                 else
                  if report_errors then
                   CGMessagePos(hp.fileinfo,errmsg);
                 exit;
               end;
             inlinen :
               begin
                 if ((valid_const in opts) and
                     (tinlinenode(hp).inlinenumber in [in_typeof_x])) or
                    (tinlinenode(hp).inlinenumber in [in_unaligned_x]) then
                   result:=true
                 else
                   if report_errors then
                    CGMessagePos(hp.fileinfo,type_e_variable_id_expected);
                 exit;
               end;
             dataconstn:
               begin
                 { only created internally, so no additional checks necessary }
                 result:=true;
                 exit;
               end;
             loadn :
               begin
                 case tloadnode(hp).symtableentry.typ of
                   absolutevarsym,
                   staticvarsym,
                   localvarsym,
                   paravarsym :
                     begin
                       { loop counter? }
                       if not(Valid_Const in opts) and
                          not gotderef and
                          (vo_is_loop_counter in tabstractvarsym(tloadnode(hp).symtableentry).varoptions) then
                         begin
                           if report_errors then
                             CGMessage1(parser_e_illegal_assignment_to_count_var,tloadnode(hp).symtableentry.realname);
                           exit;
                         end;
                       { read-only variable? }
                       if (tabstractvarsym(tloadnode(hp).symtableentry).varspez in [vs_const,vs_constref]) then
                        begin
                          { allow p^:= constructions with p is const parameter }
                          if gotderef or gotdynarray or (Valid_Const in opts) or
                            (loadnf_isinternal_ignoreconst in tloadnode(hp).loadnodeflags) then
                            result:=true
                          else
                            if report_errors then
                              CGMessagePos(tloadnode(hp).fileinfo,type_e_no_assign_to_const);
                          exit;
                        end;
                       result:=true;
                       exit;
                     end;
                   procsym :
                     begin
                       if (Valid_Const in opts) then
                         result:=true
                       else
                         if report_errors then
                          CGMessagePos(hp.fileinfo,type_e_variable_id_expected);
                       exit;
                     end;
                   labelsym :
                     begin
                       if (Valid_Addr in opts) then
                         result:=true
                       else
                         if report_errors then
                          CGMessagePos(hp.fileinfo,type_e_variable_id_expected);
                       exit;
                     end;
                   constsym:
                     begin
                       if (tconstsym(tloadnode(hp).symtableentry).consttyp=constresourcestring) and
                         (valid_addr in opts) then
                         result:=true
                       else
                         if report_errors then
                          CGMessagePos(hp.fileinfo,type_e_variable_id_expected);
                       exit;
                     end;
                   else
                     begin
                       if report_errors then
                        CGMessagePos(hp.fileinfo,type_e_variable_id_expected);
                       exit;
                     end;
                 end;
               end;
             else
               begin
                 if report_errors then
                  CGMessagePos(hp.fileinfo,type_e_variable_id_expected);
                 exit;
               end;
            end;
         end;
      end;


    function  valid_for_var(p:tnode; report_errors: boolean):boolean;
      begin
        valid_for_var:=valid_for_assign(p,[],report_errors);
      end;


    function  valid_for_formal_var(p : tnode; report_errors: boolean) : boolean;
      begin
        valid_for_formal_var:=valid_for_assign(p,[valid_void],report_errors);
      end;


    function  valid_for_formal_const(p : tnode; report_errors: boolean) : boolean;
      begin
        valid_for_formal_const:=(p.resultdef.typ=formaldef) or
          valid_for_assign(p,[valid_void,valid_const,valid_property],report_errors);
      end;


    function  valid_for_assignment(p:tnode; report_errors: boolean):boolean;
      begin
        valid_for_assignment:=valid_for_assign(p,[valid_property,valid_packed],report_errors);
      end;


    function  valid_for_loopvar(p:tnode; report_errors: boolean):boolean;
      begin
        valid_for_loopvar:=valid_for_assign(p,[valid_property],report_errors);
      end;


    function  valid_for_addr(p : tnode; report_errors: boolean) : boolean;
      begin
        result:=valid_for_assign(p,[valid_const,valid_addr,valid_void],report_errors);
      end;


    procedure var_para_allowed(var eq:tequaltype;def_from,def_to:Tdef; fromnode: tnode);
      begin
        { Note: eq must be already valid, it will only be updated! }
        case def_to.typ of
          formaldef :
            begin
              { all types can be passed to a formaldef,
                but it is not the prefered way }
              if not is_constnode(fromnode) then
                eq:=te_convert_l2
              else
                eq:=te_incompatible;
            end;
          orddef :
            begin
              { allows conversion from word to integer and
                byte to shortint, but only for TP7 compatibility }
              if (m_tp7 in current_settings.modeswitches) and
                 (def_from.typ=orddef) and
                 (def_from.size=def_to.size) then
                eq:=te_convert_l1;
            end;
          arraydef :
            begin
              if is_open_array(def_to) then
                begin
                  if is_dynamic_array(def_from) and
                     equal_defs(tarraydef(def_from).elementdef,tarraydef(def_to).elementdef) then
                    eq:=te_convert_l2
                  else
                    if equal_defs(def_from,tarraydef(def_to).elementdef) then
                      eq:=te_convert_l3;
                end;
            end;
          pointerdef :
            begin
              { an implicit pointer conversion is allowed }
              if (def_from.typ=pointerdef) then
                eq:=te_convert_l1;
            end;
          stringdef :
            begin
              { all shortstrings are allowed, size is not important }
              if is_shortstring(def_from) and
                 is_shortstring(def_to) then
                eq:=te_equal;
            end;
          objectdef :
            begin
              { child objects can be also passed }
              { in non-delphi mode, otherwise    }
              { they must match exactly, except  }
              { if they are objects              }
              if (def_from.typ=objectdef) and
                 (
                  (tobjectdef(def_from).objecttype=odt_object) and
                  (tobjectdef(def_to).objecttype=odt_object)
                 ) and
                 (tobjectdef(def_from).is_related(tobjectdef(def_to))) then
                eq:=te_convert_l1;
            end;
          filedef :
            begin
              { an implicit file conversion is also allowed }
              { from a typed file to an untyped one           }
              if (def_from.typ=filedef) and
                 (tfiledef(def_from).filetyp = ft_typed) and
                 (tfiledef(def_to).filetyp = ft_untyped) then
                eq:=te_convert_l1;
            end;
        end;
      end;


    procedure para_allowed(var eq:tequaltype;p:tcallparanode;def_to:tdef);
      var
        acn: tarrayconstructornode;
        realprocdef: tprocdef;
        tmpeq: tequaltype;
      begin
        { Note: eq must be already valid, it will only be updated! }
        case def_to.typ of
          formaldef :
            begin
              { all types can be passed to a formaldef }
              eq:=te_equal;
            end;
          stringdef :
            begin
              { to support ansi/long/wide strings in a proper way }
              { string and string[10] are assumed as equal }
              { when searching the correct overloaded procedure   }
              if (p.resultdef.typ=stringdef) and
                 (tstringdef(def_to).stringtype=tstringdef(p.resultdef).stringtype) then
                eq:=te_equal
              else
              { Passing a constant char to ansistring or shortstring or
                a widechar to widestring then handle it as equal. }
               if (p.left.nodetype=ordconstn) and
                  (
                   is_char(p.resultdef) and
                   (is_shortstring(def_to) or is_ansistring(def_to))
                  ) or
                  (
                   is_widechar(p.resultdef) and
                   (is_widestring(def_to) or is_unicodestring(def_to))
                  ) then
                eq:=te_equal
            end;
          setdef :
            begin
              { set can also be a not yet converted array constructor }
              if (p.resultdef.typ=arraydef) and
                 is_array_constructor(p.resultdef) and
                 not is_variant_array(p.resultdef) then
                eq:=te_equal;
            end;
          procvardef :
            begin
              tmpeq:=te_incompatible;
              { in tp/macpas mode proc -> procvar is allowed }
              if ((m_tp_procvar in current_settings.modeswitches) or
                  (m_mac_procvar in current_settings.modeswitches)) and
                 (p.left.nodetype=calln) then
                tmpeq:=proc_to_procvar_equal(tprocdef(tcallnode(p.left).procdefinition),tprocvardef(def_to),false);
              if (tmpeq=te_incompatible) and
                 (m_nested_procvars in current_settings.modeswitches) and
                 is_proc2procvar_load(p.left,realprocdef) then
                tmpeq:=proc_to_procvar_equal(realprocdef,tprocvardef(def_to),false);
              if (tmpeq=te_incompatible) and
                 (m_mac in current_settings.modeswitches) and
                 is_ambiguous_funcret_load(p.left,realprocdef) then
                tmpeq:=proc_to_procvar_equal(realprocdef,tprocvardef(def_to),false);
              if tmpeq<>te_incompatible then
                eq:=tmpeq;
            end;
          arraydef :
            begin
              { an arrayconstructor of proccalls may have to be converted to
                an array of procvars }
              if ((m_tp_procvar in current_settings.modeswitches) or
                  (m_mac_procvar in current_settings.modeswitches)) and
                 (tarraydef(def_to).elementdef.typ=procvardef) and
                 is_array_constructor(p.resultdef) and
                 not is_variant_array(p.resultdef) then
                begin
                  acn:=tarrayconstructornode(p.left);
                  if assigned(acn.left) then
                    begin
                      eq:=te_exact;
                      while assigned(acn) and
                            (eq<>te_incompatible) do
                        begin
                          if (acn.left.nodetype=calln) then
                            tmpeq:=proc_to_procvar_equal(tprocdef(tcallnode(acn.left).procdefinition),tprocvardef(tarraydef(def_to).elementdef),false)
                          else
                            tmpeq:=compare_defs(acn.left.resultdef,tarraydef(def_to).elementdef,acn.left.nodetype);
                          if tmpeq<eq then
                            eq:=tmpeq;
                          acn:=tarrayconstructornode(acn.right);
                        end;
                    end
                end;
            end;
        end;
      end;


    function allowenumop(nt:tnodetype):boolean;
      begin
        result:=(nt in [equaln,unequaln,ltn,lten,gtn,gten]) or
                ((cs_allow_enum_calc in current_settings.localswitches) and
                 (nt in [addn,subn]));
      end;


{****************************************************************************
                           TCallCandidates
****************************************************************************}

    constructor tcallcandidates.create(sym:tprocsym;st:TSymtable;ppn:tnode;ignorevisibility,allowdefaultparas,objcidcall,explicitunit,searchhelpers,anoninherited:boolean);
      begin
        if not assigned(sym) then
          internalerror(200411015);
        FOperator:=NOTOKEN;
        FProcsym:=sym;
        FProcsymtable:=st;
        FParanode:=ppn;
        create_candidate_list(ignorevisibility,allowdefaultparas,objcidcall,explicitunit,searchhelpers,anoninherited);
      end;


    constructor tcallcandidates.create_operator(op:ttoken;ppn:tnode);
      begin
        FOperator:=op;
        FProcsym:=nil;
        FProcsymtable:=nil;
        FParanode:=ppn;
        create_candidate_list(false,false,false,false,false,false);
      end;


    destructor tcallcandidates.destroy;
      var
        hpnext,
        hp : pcandidate;
      begin
        hp:=FCandidateProcs;
        while assigned(hp) do
         begin
           hpnext:=hp^.next;
           dispose(hp);
           hp:=hpnext;
         end;
      end;


    procedure tcallcandidates.collect_overloads_in_struct(structdef:tabstractrecorddef;ProcdefOverloadList:TFPObjectList;searchhelpers,anoninherited:boolean);

      function processprocsym(srsym:tprocsym; out foundanything: boolean):boolean;
        var
          j  : integer;
          pd : tprocdef;
        begin
          { add all definitions }
          result:=false;
          foundanything:=false;
          for j:=0 to srsym.ProcdefList.Count-1 do
            begin
              pd:=tprocdef(srsym.ProcdefList[j]);
              { in case of anonymous inherited, only match procdefs identical
                to the current one (apart from hidden parameters), rather than
                anything compatible to the parameters -- except in case of
                the presence of a messagestr/int, in which case those have to
                match exactly }
              if anoninherited then
                if po_msgint in current_procinfo.procdef.procoptions then
                  begin
                    if not(po_msgint in pd.procoptions) or
                       (pd.messageinf.i<>current_procinfo.procdef.messageinf.i) then
                      continue
                  end
                else if po_msgstr in current_procinfo.procdef.procoptions then
                  begin
                    if not(po_msgstr in pd.procoptions) or
                       (pd.messageinf.str^<>current_procinfo.procdef.messageinf.str^) then
                      continue
                  end
                else if (compare_paras(current_procinfo.procdef.paras,pd.paras,cp_all,[cpo_ignorehidden])<te_equal) then
                  continue;
              foundanything:=true;
              { Store first procsym found }
              if not assigned(FProcsym) then
                FProcsym:=tprocsym(srsym);
              if po_overload in pd.procoptions then
                result:=true;
              ProcdefOverloadList.Add(srsym.ProcdefList[j]);
            end;
        end;

      var
        srsym      : tsym;
        hashedid   : THashedIDString;
        hasoverload,
        foundanything : boolean;
        helperdef  : tobjectdef;
      begin
        if FOperator=NOTOKEN then
          hashedid.id:=FProcsym.name
        else
          hashedid.id:=overloaded_names[FOperator];
        hasoverload:=false;
        while assigned(structdef) do
         begin
           { first search in helpers for this type }
           if (is_class(structdef) or is_record(structdef))
               and searchhelpers then
             begin
               if search_last_objectpascal_helper(structdef,nil,helperdef) then
                 begin
                   srsym:=nil;
                   while assigned(helperdef) do
                     begin
                       srsym:=tsym(helperdef.symtable.FindWithHash(hashedid));
                       if assigned(srsym) and
                           { Delphi allows hiding a property by a procedure with the same name }
                           (srsym.typ=procsym) then
                         begin
                           hasoverload:=processprocsym(tprocsym(srsym),foundanything);
                           { when there is no explicit overload we stop searching }
                           if foundanything and
                              not hasoverload then
                             break;
                         end;
                       helperdef:=helperdef.childof;
                     end;
                   if not hasoverload and assigned(srsym) then
                     exit;
                 end;
             end;
           { now search in the type itself }
           srsym:=tprocsym(structdef.symtable.FindWithHash(hashedid));
           if assigned(srsym) and
              { Delphi allows hiding a property by a procedure with the same name }
              (srsym.typ=procsym) then
             begin
               hasoverload:=processprocsym(tprocsym(srsym),foundanything);
               { when there is no explicit overload we stop searching }
               if foundanything and
                  not hasoverload then
                 break;
             end;
           if is_objectpascal_helper(structdef) and
              (tobjectdef(structdef).typ in [recorddef,objectdef]) then
             begin
               { search methods in the extended type as well }
               srsym:=tprocsym(tabstractrecorddef(tobjectdef(structdef).extendeddef).symtable.FindWithHash(hashedid));
               if assigned(srsym) and
                  { Delphi allows hiding a property by a procedure with the same name }
                  (srsym.typ=procsym) then
                 begin
                   hasoverload:=processprocsym(tprocsym(srsym),foundanything);
                   { when there is no explicit overload we stop searching }
                   if foundanything and
                      not hasoverload then
                     break;
                 end;
             end;
           { next parent }
           if (structdef.typ=objectdef) then
             structdef:=tobjectdef(structdef).childof
           else
             structdef:=nil;
         end;
      end;


    procedure tcallcandidates.collect_overloads_in_units(ProcdefOverloadList:TFPObjectList; objcidcall,explicitunit: boolean);
      var
        j          : integer;
        pd         : tprocdef;
        srsymtable : TSymtable;
        srsym      : tsym;
        checkstack : psymtablestackitem;
        hashedid   : THashedIDString;
        hasoverload : boolean;
      begin
        { we search all overloaded operator definitions in the symtablestack. The found
          entries are only added to the procs list and not the procsym, because
          the list can change in every situation }
        if FOperator=NOTOKEN then
          begin
            if not objcidcall then
              hashedid.id:=FProcsym.name
            else
              hashedid.id:=class_helper_prefix+FProcsym.name;
          end
        else
          hashedid.id:=overloaded_names[FOperator];

        checkstack:=symtablestack.stack;
        if assigned(FProcsymtable) then
          begin
            while assigned(checkstack) and
                  (checkstack^.symtable<>FProcsymtable) do
              checkstack:=checkstack^.next;
          end;
        while assigned(checkstack) do
          begin
            srsymtable:=checkstack^.symtable;
            { if the unit in which the routine has to be searched has been
              specified explicitly, stop searching after its symtable(s) have
              been checked (can be both the static and the global symtable
              in case it's the current unit itself) }
            if explicitunit and
               (FProcsymtable.symtabletype in [globalsymtable,staticsymtable]) and
               (srsymtable.moduleid<>FProcsymtable.moduleid) then
              break;
            if srsymtable.symtabletype in [localsymtable,staticsymtable,globalsymtable] then
              begin
                srsym:=tsym(srsymtable.FindWithHash(hashedid));
                if assigned(srsym) and
                   (srsym.typ=procsym) then
                  begin
                    { Store first procsym found }
                    if not assigned(FProcsym) then
                      FProcsym:=tprocsym(srsym);
                    { add all definitions }
                    hasoverload:=false;
                    for j:=0 to tprocsym(srsym).ProcdefList.Count-1 do
                      begin
                        pd:=tprocdef(tprocsym(srsym).ProcdefList[j]);
                        if po_overload in pd.procoptions then
                          hasoverload:=true;
                        ProcdefOverloadList.Add(tprocsym(srsym).ProcdefList[j]);
                      end;
                    { when there is no explicit overload we stop searching,
                      except for Objective-C methods called via id }
                    if not hasoverload and
                       not objcidcall then
                      break;
                  end;
              end;
            checkstack:=checkstack^.next
          end;
      end;


    procedure tcallcandidates.create_candidate_list(ignorevisibility,allowdefaultparas,objcidcall,explicitunit,searchhelpers,anoninherited:boolean);
      var
        j     : integer;
        pd    : tprocdef;
        hp    : pcandidate;
        pt    : tcallparanode;
        found : boolean;
        st    : TSymtable;
        contextstructdef : tabstractrecorddef;
        ProcdefOverloadList : TFPObjectList;
        cpoptions : tcompare_paras_options;
      begin
        FCandidateProcs:=nil;

        { Find all available overloads for this procsym }
        ProcdefOverloadList:=TFPObjectList.Create(false);
        if not objcidcall and
           (FOperator=NOTOKEN) and
           (FProcsym.owner.symtabletype in [objectsymtable,recordsymtable]) then
          collect_overloads_in_struct(tabstractrecorddef(FProcsym.owner.defowner),ProcdefOverloadList,searchhelpers,anoninherited)
        else
        if (FOperator<>NOTOKEN) then
          begin
            { check operands and if they contain records then search in records,
              then search in unit }
            pt:=tcallparanode(FParaNode);
            while assigned(pt) do
              begin
                if (pt.resultdef.typ=recorddef) then
                  collect_overloads_in_struct(tabstractrecorddef(pt.resultdef),ProcdefOverloadList,searchhelpers,anoninherited);
                pt:=tcallparanode(pt.right);
              end;
            collect_overloads_in_units(ProcdefOverloadList,objcidcall,explicitunit);
          end
        else
          collect_overloads_in_units(ProcdefOverloadList,objcidcall,explicitunit);

        { determine length of parameter list.
          for operators also enable the variant-operators if
          a variant parameter is passed }
        FParalength:=0;
        FAllowVariant:=(FOperator=NOTOKEN);
        pt:=tcallparanode(FParaNode);
        while assigned(pt) do
          begin
            if (pt.resultdef.typ=variantdef) then
              FAllowVariant:=true;
            inc(FParalength);
            pt:=tcallparanode(pt.right);
          end;

        { when the class passed is defined in this unit we
          need to use the scope of that class. This is a trick
          that can be used to access protected members in other
          units. At least kylix supports it this way (PFV) }
        if assigned(FProcSymtable) and
           (
            (FProcSymtable.symtabletype in [ObjectSymtable,recordsymtable]) or
            ((FProcSymtable.symtabletype=withsymtable) and
             (FProcSymtable.defowner.typ in [objectdef,recorddef]))
           ) and
           (FProcSymtable.defowner.owner.symtabletype in [globalsymtable,staticsymtable,objectsymtable,recordsymtable]) and
           FProcSymtable.defowner.owner.iscurrentunit then
          contextstructdef:=tabstractrecorddef(FProcSymtable.defowner)
        else
          contextstructdef:=current_structdef;

        { symtable is needed later to calculate the distance }
        if assigned(FProcsym) then
          st:=FProcsym.Owner
        else
          st:=nil;
        { Process all found overloads }
        for j:=0 to ProcdefOverloadList.Count-1 do
          begin
            pd:=tprocdef(ProcdefOverloadList[j]);

            { only when the # of parameter are supported by the procedure and
              it is visible }
            if (FParalength>=pd.minparacount) and
               (
                (
                 allowdefaultparas and
                 (
                  (FParalength<=pd.maxparacount) or
                  (po_varargs in pd.procoptions)
                 )
                ) or
                (
                 not allowdefaultparas and
                 (FParalength=pd.maxparacount)
                )
               ) and
               (
                ignorevisibility or
                not (pd.owner.symtabletype in [objectsymtable,recordsymtable]) or
                is_visible_for_object(pd,contextstructdef)
               ) then
              begin
                { don't add duplicates, only compare visible parameters for the user }
                cpoptions:=[cpo_ignorehidden];
                if (po_compilerproc in pd.procoptions) then
                  cpoptions:=cpoptions+[cpo_compilerproc];
                if (po_rtlproc in pd.procoptions) then
                  cpoptions:=cpoptions+[cpo_rtlproc];
                found:=false;
                hp:=FCandidateProcs;
                while assigned(hp) do
                  begin
                    if (compare_paras(hp^.data.paras,pd.paras,cp_value_equal_const,cpoptions)>=te_equal) and
                       (not(po_objc in pd.procoptions) or
                        (pd.messageinf.str^=hp^.data.messageinf.str^)) then
                      begin
                        found:=true;
                        break;
                      end;
                    hp:=hp^.next;
                  end;
                if not found then
                  proc_add(st,pd,objcidcall);
              end;
          end;

        ProcdefOverloadList.Free;
      end;


    function tcallcandidates.proc_add(st:tsymtable;pd:tprocdef;objcidcall: boolean):pcandidate;
      var
        defaultparacnt : integer;
      begin
        { generate new candidate entry }
        new(result);
        fillchar(result^,sizeof(tcandidate),0);
        result^.data:=pd;
        result^.next:=FCandidateProcs;
        FCandidateProcs:=result;
        inc(FProccnt);
        { Find last parameter, skip all default parameters
          that are not passed. Ignore this skipping for varargs }
        result^.firstparaidx:=pd.paras.count-1;
        if not(po_varargs in pd.procoptions) then
         begin
           { ignore hidden parameters }
           while (result^.firstparaidx>=0) and (vo_is_hidden_para in tparavarsym(pd.paras[result^.firstparaidx]).varoptions) do
             dec(result^.firstparaidx);
           defaultparacnt:=pd.maxparacount-FParalength;
           if defaultparacnt>0 then
             begin
               if defaultparacnt>result^.firstparaidx+1 then
                 internalerror(200401141);
               dec(result^.firstparaidx,defaultparacnt);
             end;
         end;
        { Give a small penalty for overloaded methods not in
          defined the current class/unit }
        {  when calling Objective-C methods via id.method, then the found
           procsym will be inside an arbitrary ObjectSymtable, and we don't
           want togive the methods of that particular objcclass precedence over
           other methods, so instead check against the symtable in which this
           objcclass is defined }
        if objcidcall then
          st:=st.defowner.owner;
        if (st<>pd.owner) then
          result^.ordinal_distance:=result^.ordinal_distance+1.0;
      end;


    procedure tcallcandidates.list(all:boolean);
      var
        hp : pcandidate;
      begin
        hp:=FCandidateProcs;
        while assigned(hp) do
         begin
           if all or
              (not hp^.invalid) then
             MessagePos1(hp^.data.fileinfo,sym_h_param_list,hp^.data.fullprocname(false));
           hp:=hp^.next;
         end;
      end;


{$ifdef EXTDEBUG}
    procedure tcallcandidates.dump_info(lvl:longint);

        function ParaTreeStr(p:tcallparanode):string;
        begin
          result:='';
          while assigned(p) do
           begin
             if result<>'' then
              result:=','+result;
             result:=p.resultdef.typename+result;
             p:=tcallparanode(p.right);
           end;
        end;

      var
        hp : pcandidate;
        i  : integer;
        currpara : tparavarsym;
      begin
        if not CheckVerbosity(lvl) then
         exit;
        Comment(lvl+V_LineInfo,'Overloaded callnode: '+FProcsym.name+'('+ParaTreeStr(tcallparanode(FParaNode))+')');
        hp:=FCandidateProcs;
        while assigned(hp) do
         begin
           Comment(lvl,'  '+hp^.data.fullprocname(false));
           if (hp^.invalid) then
            Comment(lvl,'   invalid')
           else
            begin
              Comment(lvl,'   ex: '+tostr(hp^.exact_count)+
                          ' eq: '+tostr(hp^.equal_count)+
                          ' l1: '+tostr(hp^.cl1_count)+
                          ' l2: '+tostr(hp^.cl2_count)+
                          ' l3: '+tostr(hp^.cl3_count)+
                          ' l4: '+tostr(hp^.cl4_count)+
                          ' l5: '+tostr(hp^.cl5_count)+
                          ' oper: '+tostr(hp^.coper_count)+
                          ' ord: '+realtostr(hp^.ordinal_distance));
              { Print parameters in left-right order }
              for i:=0 to hp^.data.paras.count-1 do
               begin
                 currpara:=tparavarsym(hp^.data.paras[i]);
                 if not(vo_is_hidden_para in currpara.varoptions) then
                   Comment(lvl,'    - '+currpara.vardef.typename+' : '+EqualTypeName[currpara.eqval]);
               end;
            end;
           hp:=hp^.next;
         end;
      end;
{$endif EXTDEBUG}


    procedure tcallcandidates.get_information;
      var
        hp       : pcandidate;
        currpara : tparavarsym;
        paraidx  : integer;
        currparanr : byte;
        rfh,rth  : double;
        objdef   : tobjectdef;
        def_from,
        def_to   : tdef;
        currpt,
        pt       : tcallparanode;
        eq       : tequaltype;
        convtype : tconverttype;
        pdtemp,
        pdoper   : tprocdef;
        releasecurrpt : boolean;
        cdoptions : tcompare_defs_options;
        n : tnode;

    {$push}
    {$r-}
    {$q-}
      const
        inf=1.0/0.0;
    {$pop}
      begin
        cdoptions:=[cdo_check_operator];
        if FAllowVariant then
          include(cdoptions,cdo_allow_variant);
        { process all procs }
        hp:=FCandidateProcs;
        while assigned(hp) do
         begin
           { We compare parameters in reverse order (right to left),
             the firstpara is already pointing to the last parameter
             were we need to start comparing }
           currparanr:=FParalength;
           paraidx:=hp^.firstparaidx;
           while (paraidx>=0) and (vo_is_hidden_para in tparavarsym(hp^.data.paras[paraidx]).varoptions) do
             dec(paraidx);
           pt:=tcallparanode(FParaNode);
           while assigned(pt) and (paraidx>=0) do
            begin
              currpara:=tparavarsym(hp^.data.paras[paraidx]);
              { currpt can be changed from loadn to calln when a procvar
                is passed. This is to prevent that the change is permanent }
              currpt:=pt;
              releasecurrpt:=false;
              { retrieve current parameter definitions to compares }
              eq:=te_incompatible;
              def_from:=currpt.resultdef;
              def_to:=currpara.vardef;
              if not(assigned(def_from)) then
               internalerror(200212091);
              if not(
                     assigned(def_to) or
                     ((po_varargs in hp^.data.procoptions) and
                      (currparanr>hp^.data.minparacount))
                    ) then
               internalerror(200212092);

              { Convert tp procvars when not expecting a procvar }
             if (currpt.left.resultdef.typ=procvardef) and
                not(def_to.typ in [procvardef,formaldef]) and
                 { Only convert to call when there is no overload or the return type
                   is equal to the expected type. }
                 (
                  (count=1) or
                  equal_defs(tprocvardef(currpt.left.resultdef).returndef,def_to)
                 ) then
                begin
                  releasecurrpt:=true;
                  currpt:=tcallparanode(pt.getcopy);
                  if maybe_call_procvar(currpt.left,true) then
                    begin
                      currpt.resultdef:=currpt.left.resultdef;
                      def_from:=currpt.left.resultdef;
                    end;
                end;

             { If we expect a procvar and the left is loadnode that
               returns a procdef we need to find the correct overloaded
               procdef that matches the expected procvar. The loadnode
               temporary returned the first procdef (PFV) }
             if (def_to.typ=procvardef) and
                (currpt.left.nodetype=loadn) and
                (currpt.left.resultdef.typ=procdef) then
               begin
                 pdtemp:=tprocsym(Tloadnode(currpt.left).symtableentry).Find_procdef_byprocvardef(Tprocvardef(def_to));
                 if assigned(pdtemp) then
                   begin
                     tloadnode(currpt.left).setprocdef(pdtemp);
                     currpt.resultdef:=currpt.left.resultdef;
                     def_from:=currpt.left.resultdef;
                   end;
               end;

              { varargs are always equal, but not exact }
              if (po_varargs in hp^.data.procoptions) and
                 (currparanr>hp^.data.minparacount) and
                 not is_array_of_const(def_from) and
                 not is_array_constructor(def_from) then
                eq:=te_equal
              else
              { same definition -> exact }
               if (def_from=def_to) then
                 eq:=te_exact
              else
              { for value and const parameters check if a integer is constant or
                included in other integer -> equal and calc ordinal_distance }
               if not(currpara.varspez in [vs_var,vs_out]) and
                  is_integer(def_from) and
                  is_integer(def_to) and
                  is_in_limit(def_from,def_to) then
                 begin
                   eq:=te_equal;
                   hp^.ordinal_distance:=hp^.ordinal_distance+
                     abs(bestreal(torddef(def_from).low)-bestreal(torddef(def_to).low));
                   rth:=bestreal(torddef(def_to).high);
                   rfh:=bestreal(torddef(def_from).high);
                   hp^.ordinal_distance:=hp^.ordinal_distance+abs(rth-rfh);
                   { Give wrong sign a small penalty, this is need to get a diffrence
                     from word->[longword,longint] }
                   if is_signed(def_from)<>is_signed(def_to) then
{$push}
{$r-}
{$q-}
                     hp^.ordinal_distance:=nextafter(hp^.ordinal_distance,inf);
{$pop}
                 end
              else
              { for value and const parameters check precision of real, give
                penalty for loosing of precision. var and out parameters must match exactly }
               if not(currpara.varspez in [vs_var,vs_out]) and
                  is_real(def_from) and
                  is_real(def_to) then
                 begin
                   eq:=te_equal;
                   if is_extended(def_to) then
                     rth:=4
                   else
                     if is_double (def_to) then
                       rth:=2
                   else
                     rth:=1;
                   if is_extended(def_from) then
                     rfh:=4
                   else
                     if is_double (def_from) then
                       rfh:=2
                   else
                     rfh:=1;
                   { penalty for shrinking of precision }
                   if rth<rfh then
                     rfh:=(rfh-rth)*16
                   else
                     rfh:=rth-rfh;
                   hp^.ordinal_distance:=hp^.ordinal_distance+rfh;
                 end
              else
              { related object parameters also need to determine the distance between the current
                object and the object we are comparing with. var and out parameters must match exactly }
               if not(currpara.varspez in [vs_var,vs_out]) and
                  (def_from.typ=objectdef) and
                  (def_to.typ=objectdef) and
                  (tobjectdef(def_from).objecttype=tobjectdef(def_to).objecttype) and
                  tobjectdef(def_from).is_related(tobjectdef(def_to)) then
                 begin
                   eq:=te_convert_l1;
                   objdef:=tobjectdef(def_from);
                   while assigned(objdef) do
                     begin
                       if objdef=def_to then
                         break;
                       hp^.ordinal_distance:=hp^.ordinal_distance+1;
                       objdef:=objdef.childof;
                     end;
                 end
               { compare_defs_ext compares sets and array constructors very poorly because
                 it has too little information. So we do explicitly a detailed comparisation,
                 see also bug #11288 (FK)
               }
               else if (def_to.typ=setdef) and is_array_constructor(currpt.left.resultdef) then
                 begin
                   n:=currpt.left.getcopy;
                   arrayconstructor_to_set(n);
                   eq:=compare_defs_ext(n.resultdef,def_to,n.nodetype,convtype,pdoper,cdoptions);
                   n.free;
                 end
              else
              { generic type comparision }
               begin
                 if not(po_compilerproc in hp^.data.procoptions) and
                    not(po_rtlproc in hp^.data.procoptions) and
                    is_ansistring(currpara.vardef) and
                    is_ansistring(currpt.left.resultdef) and
                    (tstringdef(currpara.vardef).encoding<>tstringdef(currpt.left.resultdef).encoding) and
                    ((tstringdef(currpara.vardef).encoding=globals.CP_NONE) or
                     (tstringdef(currpt.left.resultdef).encoding=globals.CP_NONE)
                    ) then
                   eq:=te_convert_l1
                 else
                   eq:=compare_defs_ext(def_from,def_to,currpt.left.nodetype,convtype,pdoper,cdoptions);

                 { when the types are not equal we need to check
                   some special case for parameter passing }
                 if (eq<te_equal) then
                  begin
                    if currpara.varspez in [vs_var,vs_out] then
                      begin
                        { para requires an equal type so the previous found
                          match was not good enough, reset to incompatible }
                        eq:=te_incompatible;
                        { var_para_allowed will return te_equal and te_convert_l1 to
                          make a difference for best matching }
                        var_para_allowed(eq,currpt.resultdef,currpara.vardef,currpt.left)
                      end
                    else
                      para_allowed(eq,currpt,def_to);
                  end;
               end;

              { univ parameters match if the size matches (don't override the
                comparison result if it was ok, since a match based on the
                "univ" character is the lowest possible match) }
                if (eq=te_incompatible) and
                   currpara.univpara and
                   is_valid_univ_para_type(def_from) and
                   (def_from.size=def_to.size) then
                  eq:=te_convert_l5;

               { when a procvar was changed to a call an exact match is
                downgraded to equal. This way an overload call with the
                procvar is choosen. See tb0471 (PFV) }
              if (pt<>currpt) and (eq=te_exact) then
                eq:=te_equal;

              { increase correct counter }
              case eq of
                te_exact :
                  inc(hp^.exact_count);
                te_equal :
                  inc(hp^.equal_count);
                te_convert_l1 :
                  inc(hp^.cl1_count);
                te_convert_l2 :
                  inc(hp^.cl2_count);
                te_convert_l3 :
                  inc(hp^.cl3_count);
                te_convert_l4 :
                  inc(hp^.cl4_count);
                te_convert_l5 :
                  inc(hp^.cl5_count);
                te_convert_operator :
                  inc(hp^.coper_count);
                te_incompatible :
                  hp^.invalid:=true;
                else
                  internalerror(200212072);
              end;

              { stop checking when an incompatible parameter is found }
              if hp^.invalid then
               begin
                 { store the current parameter info for
                   a nice error message when no procedure is found }
                 hp^.wrongparaidx:=paraidx;
                 hp^.wrongparanr:=currparanr;
                 break;
               end;

{$ifdef EXTDEBUG}
              { store equal in node tree for dump }
              currpara.eqval:=eq;
{$endif EXTDEBUG}

              { maybe release temp currpt }
              if releasecurrpt then
                currpt.free;

              { next parameter in the call tree }
              pt:=tcallparanode(pt.right);

              { next parameter for definition, only goto next para
                if we're out of the varargs }
              if not(po_varargs in hp^.data.procoptions) or
                 (currparanr<=hp^.data.maxparacount) then
               begin
                 { Ignore vs_hidden parameters }
                 repeat
                   dec(paraidx);
                 until (paraidx<0) or not(vo_is_hidden_para in tparavarsym(hp^.data.paras[paraidx]).varoptions);
               end;
              dec(currparanr);
            end;
           if not(hp^.invalid) and
              (assigned(pt) or (paraidx>=0) or (currparanr<>0)) then
             internalerror(200212141);
           { next candidate }
           hp:=hp^.next;
         end;
      end;


    function get_variantequaltype(def: tdef): tvariantequaltype;
      const
        variantorddef_cl: array[tordtype] of tvariantequaltype =
          (tve_incompatible,tve_byte,tve_word,tve_cardinal,tve_chari64,
           tve_shortint,tve_smallint,tve_longint,tve_chari64,
           tve_boolformal,tve_boolformal,tve_boolformal,tve_boolformal,
           tve_boolformal,tve_boolformal,tve_boolformal,tve_boolformal,
           tve_chari64,tve_chari64,tve_dblcurrency);
{ TODO: fixme for 128 bit floats }
        variantfloatdef_cl: array[tfloattype] of tvariantequaltype =
          (tve_single,tve_dblcurrency,tve_extended,tve_extended,
           tve_dblcurrency,tve_dblcurrency,tve_extended);
        variantstringdef_cl: array[tstringtype] of tvariantequaltype =
          (tve_sstring,tve_astring,tve_astring,tve_wstring,tve_ustring);
      begin
        case def.typ of
          orddef:
            begin
              result:=variantorddef_cl[torddef(def).ordtype];
            end;
          floatdef:
            begin
              result:=variantfloatdef_cl[tfloatdef(def).floattype];
            end;
          stringdef:
            begin
              result:=variantstringdef_cl[tstringdef(def).stringtype];
            end;
          formaldef:
            begin
              result:=tve_boolformal;
            end;
          else
            begin
              result:=tve_incompatible;
            end;
        end
      end;


    function is_better_candidate(currpd,bestpd:pcandidate):integer;
      var
        res : integer;
      begin
        {
          Return values:
            > 0 when currpd is better than bestpd
            < 0 when bestpd is better than currpd
            = 0 when both are equal

          To choose the best candidate we use the following order:
          - Incompatible flag
          - (Smaller) Number of convert operator parameters.
          - (Smaller) Number of convertlevel 2 parameters.
          - (Smaller) Number of convertlevel 1 parameters.
          - (Bigger) Number of exact parameters.
          - (Smaller) Number of equal parameters.
          - (Smaller) Total of ordinal distance. For example, the distance of a word
            to a byte is 65535-255=65280.
        }
        if bestpd^.invalid then
         begin
           if currpd^.invalid then
            res:=0
           else
            res:=1;
         end
        else
         if currpd^.invalid then
          res:=-1
        else
         begin
           { less operator parameters? }
           res:=(bestpd^.coper_count-currpd^.coper_count);
           if (res=0) then
            begin
             { less cl5 parameters? }
             res:=(bestpd^.cl5_count-currpd^.cl5_count);
             if (res=0) then
              begin
               { less cl4 parameters? }
               res:=(bestpd^.cl4_count-currpd^.cl4_count);
               if (res=0) then
                begin
                 { less cl3 parameters? }
                 res:=(bestpd^.cl3_count-currpd^.cl3_count);
                 if (res=0) then
                  begin
                    { less cl2 parameters? }
                    res:=(bestpd^.cl2_count-currpd^.cl2_count);
                    if (res=0) then
                     begin
                       { less cl1 parameters? }
                       res:=(bestpd^.cl1_count-currpd^.cl1_count);
                       if (res=0) then
                        begin
                          { more exact parameters? }
                          res:=(currpd^.exact_count-bestpd^.exact_count);
                          if (res=0) then
                           begin
                             { less equal parameters? }
                             res:=(bestpd^.equal_count-currpd^.equal_count);
                             if (res=0) then
                              begin
                                { smaller ordinal distance? }
                                if (currpd^.ordinal_distance<bestpd^.ordinal_distance) then
                                 res:=1
                                else
                                 if (currpd^.ordinal_distance>bestpd^.ordinal_distance) then
                                  res:=-1
                                else
                                 res:=0;
                              end;
                           end;
                        end;
                     end;
                  end;
                end;
              end;
            end;
         end;
        is_better_candidate:=res;
      end;


{ Delphi precedence rules extracted from test programs. Only valid if passing
  a variant parameter to overloaded procedures expecting exactly one parameter.

  single > (char, currency, int64, shortstring, ansistring, widestring, extended, double)
  double/currency > (char, int64, shortstring, ansistring, widestring, extended)
  extended > (char, int64, shortstring, ansistring, widestring)
  longint/cardinal > (int64, shortstring, ansistring, widestring, extended, double, single, char, currency)
  smallint > (longint, int64, shortstring, ansistring, widestring, extended, double single, char, currency);
  word > (longint, cardinal, int64, shortstring, ansistring, widestring, extended, double single, char, currency);
  shortint > (longint, smallint, int64, shortstring, ansistring, widestring, extended, double, single, char, currency)
  byte > (longint, cardinal, word, smallint, int64, shortstring, ansistring, widestring, extended, double, single, char, currency);
  boolean/formal > (char, int64, shortstring, ansistring, widestring)
  shortstring > (char, int64, ansistring, widestring)
  ansistring > (char, int64, widestring)
  widestring > (char, int64)

  Relations not mentioned mean that they conflict: no decision possible }

    function is_better_candidate_single_variant(currpd,bestpd:pcandidate):integer;

      function calculate_relation(const currvcl, bestvcl, testvcl:
          tvariantequaltype; const conflictvcls: tvariantequaltypes):integer;
        begin
          { if (bestvcl=conflictvcl) or
               (currvcl=conflictvcl) then
              result:=0
            else if (bestvcl=testvcl) then
              result:=-1
            else result:=1 }
          result:=1-2*ord(bestvcl=testvcl)+
                  ord(currvcl in conflictvcls)-ord(bestvcl in conflictvcls);
        end;


        function getfirstrealparaidx(pd: pcandidate): integer;
          begin
            { can be different for currpd and bestpd in case of overloaded }
            { functions, e.g. lowercase():char and lowercase():shortstring }
            { (depending on the calling convention and parameter order)    }
            result:=pd^.firstparaidx;
            while (result>=0) and (vo_is_hidden_para in tparavarsym(pd^.data.paras[result]).varoptions) do
              dec(result);
            if (vo_is_hidden_para in tparavarsym(pd^.data.paras[result]).varoptions) then
              internalerror(2006122803);
          end;

      var
        currpara, bestpara: tparavarsym;
        currvcl, bestvcl: tvariantequaltype;
      begin
        {
          Return values:
            > 0 when currpd is better than bestpd
            < 0 when bestpd is better than currpd
            = 0 when both are equal
        }
        currpara:=tparavarsym(currpd^.data.paras[getfirstrealparaidx(currpd)]);
        bestpara:=tparavarsym(bestpd^.data.paras[getfirstrealparaidx(bestpd)]);

        { if one of the parameters is a regular variant, fall back to the }
        { default algorithm                                               }
        if (currpara.vardef.typ = variantdef) or
           (bestpara.vardef.typ = variantdef) then
          begin
            result:=is_better_candidate(currpd,bestpd);
            exit;
          end;

        currvcl:=get_variantequaltype(currpara.vardef);
        bestvcl:=get_variantequaltype(bestpara.vardef);

        { sanity check }
        result:=-5;

        { if both are the same, there is a conflict }
        if (currvcl=bestvcl) then
          result:=0
        { if one of the two cannot be used as variant, the other is better }
        else if (bestvcl=tve_incompatible) then
          result:=1
        else if (currvcl=tve_incompatible) then
          result:=-1
        { boolean and formal are better than chari64str, but conflict with }
        { everything else                                                  }
        else if (currvcl=tve_boolformal) or
                (bestvcl=tve_boolformal) then
          if (currvcl=tve_boolformal) then
            result:=ord(bestvcl in [tve_chari64,tve_sstring,tve_astring,tve_wstring,tve_ustring])
          else
            result:=-ord(currvcl in [tve_chari64,tve_sstring,tve_astring,tve_wstring,tve_ustring])
        { byte is better than everything else (we assume both aren't byte, }
        { since there's only one parameter and that one can't be the same) }
        else if (currvcl=tve_byte) or
                (bestvcl=tve_byte) then
          result:=calculate_relation(currvcl,bestvcl,tve_byte,[tve_shortint])
        { shortint conflicts with word and cardinal, but is better than    }
        { everything else but byte (which has already been handled)        }
        else if (currvcl=tve_shortint) or
                (bestvcl=tve_shortint) then
          result:=calculate_relation(currvcl,bestvcl,tve_shortint,[tve_word, tve_cardinal])
        { word conflicts with smallint, but is better than everything else }
        { but shortint and byte (which has already been handled)           }
        else if (currvcl=tve_word) or
                (bestvcl=tve_word) then
          result:=calculate_relation(currvcl,bestvcl,tve_word,[tve_smallint])
        { smallint conflicts with cardinal, but is better than everything  }
        { which has not yet been tested                                    }
        else if (currvcl=tve_smallint) or
                (bestvcl=tve_smallint) then
          result:=calculate_relation(currvcl,bestvcl,tve_smallint,[tve_cardinal])
        { cardinal conflicts with each longint and is better than everything }
        { which has not yet been tested                                      }
        else if (currvcl=tve_cardinal) or
                (bestvcl=tve_cardinal) then
          result:=calculate_relation(currvcl,bestvcl,tve_cardinal,[tve_longint])
        { longint is better than everything which has not yet been tested }
        else if (currvcl=tve_longint) or
                (bestvcl=tve_longint) then
          { if bestvcl=tve_longint then
              result:=-1
            else
              result:=1 }
          result:=1-2*ord(bestvcl=tve_longint)
        { single is better than everything left }
        else if (currvcl=tve_single) or
                (bestvcl=tve_single) then
          result:=1-2*ord(bestvcl=tve_single)
        { double/comp/currency are better than everything left, and conflict }
        { with each other (but that's already tested)                        }
        else if (currvcl=tve_dblcurrency) or
                (bestvcl=tve_dblcurrency) then
          result:=1-2*ord(bestvcl=tve_dblcurrency)
        { extended is better than everything left }
        else if (currvcl=tve_extended) or
                (bestvcl=tve_extended) then
          result:=1-2*ord(bestvcl=tve_extended)
        { shortstring is better than everything left }
        else if (currvcl=tve_sstring) or
                (bestvcl=tve_sstring) then
          result:=1-2*ord(bestvcl=tve_sstring)
        { ansistring is better than everything left }
        else if (currvcl=tve_astring) or
                (bestvcl=tve_astring) then
          result:=1-2*ord(bestvcl=tve_astring)
        { widestring is better than everything left }
        else if (currvcl=tve_wstring) or
                (bestvcl=tve_wstring) then
          result:=1-2*ord(bestvcl=tve_wstring)
        { unicodestring is better than everything left }
        else if (currvcl=tve_ustring) or
                (bestvcl=tve_ustring) then
          result:=1-2*ord(bestvcl=tve_ustring);

        { all possibilities should have been checked now }
        if (result=-5) then
          internalerror(2006122805);
      end;


    function tcallcandidates.choose_best(var bestpd:tabstractprocdef; singlevariant: boolean):integer;
      var
        besthpstart,
        hp            : pcandidate;
        cntpd,
        res           : integer;
      begin
        {
          Returns the number of candidates left and the
          first candidate is returned in pdbest
        }
        { Setup the first procdef as best, only count it as a result
          when it is valid }
        bestpd:=FCandidateProcs^.data;
        if FCandidateProcs^.invalid then
         cntpd:=0
        else
         cntpd:=1;
        if assigned(FCandidateProcs^.next) then
         begin
           besthpstart:=FCandidateProcs;
           hp:=FCandidateProcs^.next;
           while assigned(hp) do
            begin
              if not singlevariant then
                res:=is_better_candidate(hp,besthpstart)
              else
                res:=is_better_candidate_single_variant(hp,besthpstart);
              if (res>0) then
               begin
                 { hp is better, flag all procs to be incompatible }
                 while (besthpstart<>hp) do
                  begin
                    besthpstart^.invalid:=true;
                    besthpstart:=besthpstart^.next;
                  end;
                 { besthpstart is already set to hp }
                 bestpd:=besthpstart^.data;
                 cntpd:=1;
               end
              else
               if (res<0) then
                begin
                  { besthpstart is better, flag current hp to be incompatible }
                  hp^.invalid:=true;
                end
              else
               begin
                 { res=0, both are valid }
                 if not hp^.invalid then
                   inc(cntpd);
               end;
              hp:=hp^.next;
            end;
         end;

        result:=cntpd;
      end;


    procedure tcallcandidates.find_wrong_para;
      var
        currparanr : smallint;
        hp : pcandidate;
        pt : tcallparanode;
        wrongpara : tparavarsym;
      begin
        { Only process the first overloaded procdef }
        hp:=FCandidateProcs;
        { Find callparanode corresponding to the argument }
        pt:=tcallparanode(FParanode);
        currparanr:=FParalength;
        while assigned(pt) and
              (currparanr>hp^.wrongparanr) do
         begin
           pt:=tcallparanode(pt.right);
           dec(currparanr);
         end;
        if (currparanr<>hp^.wrongparanr) or
           not assigned(pt) then
          internalerror(200212094);
        { Show error message, when it was a var or out parameter
          guess that it is a missing typeconv }
        wrongpara:=tparavarsym(hp^.data.paras[hp^.wrongparaidx]);
        if wrongpara.varspez in [vs_var,vs_out] then
          begin
            { Maybe passing the correct type but passing a const to var parameter }
            if (compare_defs(pt.resultdef,wrongpara.vardef,pt.nodetype)<>te_incompatible) and
               not valid_for_var(pt.left,true) then
              CGMessagePos(pt.left.fileinfo,type_e_variable_id_expected)
            else
              CGMessagePos3(pt.left.fileinfo,parser_e_call_by_ref_without_typeconv,tostr(hp^.wrongparanr),
                FullTypeName(pt.left.resultdef,wrongpara.vardef),
                FullTypeName(wrongpara.vardef,pt.left.resultdef))
          end
        else
          CGMessagePos3(pt.left.fileinfo,type_e_wrong_parameter_type,tostr(hp^.wrongparanr),
            FullTypeName(pt.left.resultdef,wrongpara.vardef),
            FullTypeName(wrongpara.vardef,pt.left.resultdef));
      end;


    procedure check_hints(const srsym: tsym; const symoptions: tsymoptions; const deprecatedmsg : pshortstring);
      begin
        if not assigned(srsym) then
          internalerror(200602051);
        if sp_hint_deprecated in symoptions then
          if (sp_has_deprecated_msg in symoptions) and (deprecatedmsg <> nil) then
            Message2(sym_w_deprecated_symbol_with_msg,srsym.realname,deprecatedmsg^)
          else
            Message1(sym_w_deprecated_symbol,srsym.realname);
        if sp_hint_experimental in symoptions then
          Message1(sym_w_experimental_symbol,srsym.realname);
        if sp_hint_platform in symoptions then
          Message1(sym_w_non_portable_symbol,srsym.realname);
        if sp_hint_library in symoptions then
          Message1(sym_w_library_symbol,srsym.realname);
        if sp_hint_unimplemented in symoptions then
          Message1(sym_w_non_implemented_symbol,srsym.realname);
      end;


    procedure check_ranges(const location: tfileposinfo; source: tnode; destdef: tdef);
      begin
        if not(cs_check_ordinal_size in current_settings.localswitches) then
          exit;
        { check if the assignment may cause a range check error }
        { if its not explicit, and only if the values are       }
        { ordinals, enumdef and floatdef                        }
        if assigned(destdef) and
          (destdef.typ in [enumdef,orddef,floatdef]) and
          not is_boolean(destdef) and
          assigned(source.resultdef) and
          (source.resultdef.typ in [enumdef,orddef,floatdef]) and
          not is_boolean(source.resultdef) and
          not is_constrealnode(source) then
         begin
           if ((destdef.size < source.resultdef.size) and
               { s80real and sc80real have a different size but the same precision }
               not((destdef.typ=floatdef) and
                   (source.resultdef.typ=floatdef) and
                   (tfloatdef(source.resultdef).floattype in [s80real,sc80real]) and
                   (tfloatdef(destdef).floattype in [s80real,sc80real]))) or
              ((destdef.typ<>floatdef) and
               (source.resultdef.typ<>floatdef) and
               not is_in_limit(source.resultdef,destdef)) then
             begin
               if (cs_check_range in current_settings.localswitches) then
                 MessagePos(location,type_w_smaller_possible_range_check)
               else
                 MessagePos(location,type_h_smaller_possible_range_check);
             end;
         end;
      end;


end.
