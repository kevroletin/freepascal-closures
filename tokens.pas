{
    Copyright (c) 1998-2002 by Florian Klaempfl, Pierre Muller

    Tokens used by the compiler

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
unit tokens;

{$i fpcdefs.inc}

interface

uses
  globtype;

type
  ttoken=(NOTOKEN,
    { operators, which can also be overloaded }
    _PLUS,
    _MINUS,
    _STAR,
    _SLASH,
    _EQ,
    _GT,
    _LT,
    _GTE,
    _LTE,
    _NE,
    _SYMDIF,
    _STARSTAR,
    _OP_AS,
    _OP_IN,
    _OP_IS,
    _OP_OR,
    _OP_AND,
    _OP_DIV,
    _OP_MOD,
    _OP_NOT,
    _OP_SHL,
    _OP_SHR,
    _OP_XOR,
    _ASSIGNMENT,
    _OP_EXPLICIT,
    _OP_ENUMERATOR,
    _OP_INC,
    _OP_DEC,
    { special chars }
    _CARET,
    _LECKKLAMMER,
    _RECKKLAMMER,
    _POINT,
    _COMMA,
    _LKLAMMER,
    _RKLAMMER,
    _COLON,
    _SEMICOLON,
    _KLAMMERAFFE,
    _POINTPOINT,
    _POINTPOINTPOINT,
    _PIPE,
    _AMPERSAND,
    _EOF,
    _ID,
    _NOID,
    _REALNUMBER,
    _INTCONST,
    _CSTRING,
    _CCHAR,
    _CWSTRING,
    _CWCHAR,
    _LSHARPBRACKET,
    _RSHARPBRACKET,
    { C like operators }
    _PLUSASN,
    _MINUSASN,
    _ANDASN,
    _ORASN,
    _STARASN,
    _SLASHASN,
    _MODASN,
    _DIVASN,
    _NOTASN,
    _XORASN,
    _GENERICSPECIALTOKEN,
    { Normal words -- ATTENTION: These words must be sorted: }
    { first in length order, then in alphabetical order.     }
    _C,
    _AS,
    _AT,
    _DO,
    _IF,
    _IN,
    _IS,
    _OF,
    _ON,
    _OR,
    _TO,
    _ADD,
    _AND,
    _ASM,
    _DEC,
    _DIV,
    _END,
    _FAR,
    _FOR,
    _INC,
    _MOD,
    _NIL,
    _NOT,
    _OUT,
    _SET,
    _SHL,
    _SHR,
    _TRY,
    _VAR,
    _XOR,
    _CASE,
    _CVAR,
    _ELSE,
    _EXIT,
    _FAIL,
    _FILE,
    _GOTO,
    _NAME,
    _NEAR,
    _READ,
    _SELF,
    _SYSV,
    _THEN,
    _TRUE,
    _TYPE,
    _UNIT,
    _UNIV,
    _USES,
    _WITH,
    _ALIAS,
    _ARRAY,
    _BEGIN,
    _BREAK,
    _CDECL,
    _CLASS,
    _CONST,
    _EQUAL,
    _FALSE,
    _FAR16,
    _FINAL,
    _INDEX,
    _LABEL,
    _LOCAL,
    _RAISE,
    _UNTIL,
    _WHILE,
    _WRITE,
    _DISPID,
    _DIVIDE,
    _DOWNTO,
    _EXCEPT,
    _EXPORT,
    _HELPER,
    _INLINE,
    _LEGACY,
    _NESTED,
    _OBJECT,
    _PACKED,
    _PASCAL,
    _PUBLIC,
    _RECORD,
    _REPEAT,
    _RESULT,
    _RETURN,
    _SEALED,
    _STATIC,
    _STORED,
    _STRICT,
    _STRING,
    _SYSTEM,
    _ASMNAME,
    _CPPDECL,
    _DEFAULT,
    _DYNAMIC,
    _EXPORTS,
    _FINALLY,
    _FORWARD,
    _GENERIC,
    _IOCHECK,
    _LIBRARY,
    _MESSAGE,
    _MODULUS,
    _PACKAGE,
    _PRIVATE,
    _PROGRAM,
    _R12BASE,
    _RTLPROC,
    _SECTION,
    _STDCALL,
    _SYSCALL,
    _VARARGS,
    _VIRTUAL,
    _ABSOLUTE,
    _ABSTRACT,
    _BASESYSV,
    _CONSTREF,
    _CONTAINS,
    _CONTINUE,
    _CPPCLASS,
    _EXPLICIT,
    _EXTERNAL,
    _FUNCTION,
    _IMPLICIT,
    _LESSTHAN,
    _LOCATION,
    _MULTIPLY,
    _MWPASCAL,
    _NEGATIVE,
    _NOTEQUAL,
    _OPERATOR,
    _OPTIONAL,
    _OVERLOAD,
    _OVERRIDE,
    _PLATFORM,
    _POSITIVE,
    _PROPERTY,
    _READONLY,
    _REGISTER,
    _REQUIRED,
    _REQUIRES,
    _RESIDENT,
    _SAFECALL,
    _SUBTRACT,
    _SYSVBASE,
    _ASSEMBLER,
    _BITPACKED,
    _BITWISEOR,
    _INHERITED,
    _INTDIVIDE,
    _INTERFACE,
    _INTERRUPT,
    _LEFTSHIFT,
    _LOGICALOR,
    _NODEFAULT,
    _OBJCCLASS,
    _OTHERWISE,
    _PROCEDURE,
    _PROTECTED,
    _PUBLISHED,
    _REFERENCE,
    _SOFTFLOAT,
    _THREADVAR,
    _WRITEONLY,
    _BITWISEAND,
    _BITWISEXOR,
    _DEPRECATED,
    _DESTRUCTOR,
    _ENUMERATOR,
    _IMPLEMENTS,
    _INTERNPROC,
    _LOGICALAND,
    _LOGICALNOT,
    _LOGICALXOR,
    _OLDFPCCALL,
    _OPENSTRING,
    _RIGHTSHIFT,
    _SPECIALIZE,
    _CONSTRUCTOR,
    _GREATERTHAN,
    _INTERNCONST,
    _REINTRODUCE,
    _SHORTSTRING,
    _COMPILERPROC,
    _EXPERIMENTAL,
    _FINALIZATION,
    _NOSTACKFRAME,
    _OBJCCATEGORY,
    _OBJCPROTOCOL,
    _WEAKEXTERNAL,
    _DISPINTERFACE,
    _UNIMPLEMENTED,
    _IMPLEMENTATION,
    _INITIALIZATION,
    _RESOURCESTRING,
    _LESSTHANOREQUAL,
    _GREATERTHANOREQUAL
  );

const
  tokenlenmin = 1;
  tokenlenmax = 18;

  { last operator which can be overloaded, the first_overloaded should
    be declared directly after NOTOKEN }
  first_overloaded = succ(NOTOKEN);
  last_overloaded  = _OP_DEC;
  last_operator = _GENERICSPECIALTOKEN;

type
  tokenrec=record
    str     : string[tokenlenmax];
    special : boolean;
    keyword : tmodeswitch;
    op      : ttoken;
  end;

  ttokenarray=array[ttoken] of tokenrec;
  ptokenarray=^ttokenarray;

  tokenidxrec=record
    first,last : ttoken;
  end;

  ptokenidx=^ttokenidx;
  ttokenidx=array[tokenlenmin..tokenlenmax,'A'..'Z'] of tokenidxrec;

const
  arraytokeninfo : ttokenarray =(
      (str:''              ;special:true ;keyword:m_none;op:NOTOKEN),
    { Operators which can be overloaded }
      (str:'+'             ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'-'             ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'*'             ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'/'             ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'='             ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'>'             ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'<'             ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'>='            ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'<='            ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'<>'            ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'><'            ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'**'            ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'as'            ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'in'            ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'is'            ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'or'            ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'and'           ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'div'           ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'mod'           ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'not'           ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'shl'           ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'shr'           ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'xor'           ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:':='            ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'explicit'      ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'enumerator'    ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'inc'           ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'dec'           ;special:true ;keyword:m_none;op:NOTOKEN),
    { Special chars }
      (str:'^'             ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'['             ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:']'             ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'.'             ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:','             ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'('             ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:')'             ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:':'             ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:';'             ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'@'             ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'..'            ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'...'           ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'|'             ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'&'             ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'end of file'   ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'identifier'    ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'non identifier';special:true ;keyword:m_none;op:NOTOKEN),
      (str:'const real'    ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'ordinal const' ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'const string'  ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'const char'    ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'const wstring' ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'const wchar'   ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'<'             ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'>'             ;special:true ;keyword:m_none;op:NOTOKEN),
    { C like operators }
      (str:'+='            ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'-='            ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'&='            ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'|='            ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'*='            ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'/='            ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:''              ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:''              ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:''              ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:''              ;special:true ;keyword:m_none;op:NOTOKEN),
      (str:'gen. spec.'    ;special:true ;keyword:m_none;op:NOTOKEN),
    { Normal words -- ATTENTION: These words must be sorted: }
    { first in length order, then in alphabetical order.     }
      (str:'C'             ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'AS'            ;special:false;keyword:m_class;op:_OP_AS),
      (str:'AT'            ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'DO'            ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'IF'            ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'IN'            ;special:false;keyword:m_all;op:_OP_IN),
      (str:'IS'            ;special:false;keyword:m_class;op:_OP_IS),
      (str:'OF'            ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'ON'            ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'OR'            ;special:false;keyword:m_all;op:_OP_OR),
      (str:'TO'            ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'ADD'           ;special:false;keyword:m_none;op:NOTOKEN), { delphi operator name }
      (str:'AND'           ;special:false;keyword:m_all;op:_OP_AND),
      (str:'ASM'           ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'DEC'           ;special:false;keyword:m_none;op:NOTOKEN), { delphi operator name }
      (str:'DIV'           ;special:false;keyword:m_all;op:_OP_DIV),
      (str:'END'           ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'FAR'           ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'FOR'           ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'INC'           ;special:false;keyword:m_none;op:NOTOKEN), { delphi operator name }
      (str:'MOD'           ;special:false;keyword:m_all;op:_OP_MOD),
      (str:'NIL'           ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'NOT'           ;special:false;keyword:m_all;op:_OP_NOT),
      (str:'OUT'           ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'SET'           ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'SHL'           ;special:false;keyword:m_all;op:_OP_SHL),
      (str:'SHR'           ;special:false;keyword:m_all;op:_OP_SHR),
      (str:'TRY'           ;special:false;keyword:m_except;op:NOTOKEN),
      (str:'VAR'           ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'XOR'           ;special:false;keyword:m_all;op:_OP_XOR),
      (str:'CASE'          ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'CVAR'          ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'ELSE'          ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'EXIT'          ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'FAIL'          ;special:false;keyword:m_none;op:NOTOKEN), { only set within constructors PM }
      (str:'FILE'          ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'GOTO'          ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'NAME'          ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'NEAR'          ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'READ'          ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'SELF'          ;special:false;keyword:m_none;op:NOTOKEN), {set inside methods only PM }
      (str:'SYSV'          ;special:false;keyword:m_none;op:NOTOKEN),   { Syscall variation on MorphOS }
      (str:'THEN'          ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'TRUE'          ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'TYPE'          ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'UNIT'          ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'UNIV'          ;special:false;keyword:m_mac;op:NOTOKEN),
      (str:'USES'          ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'WITH'          ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'ALIAS'         ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'ARRAY'         ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'BEGIN'         ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'BREAK'         ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'CDECL'         ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'CLASS'         ;special:false;keyword:m_class;op:NOTOKEN),
      (str:'CONST'         ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'EQUAL'         ;special:false;keyword:m_none;op:NOTOKEN), { delphi operator name }
      (str:'FALSE'         ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'FAR16'         ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'FINAL'         ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'INDEX'         ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'LABEL'         ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'LOCAL'         ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'RAISE'         ;special:false;keyword:m_except;op:NOTOKEN),
      (str:'UNTIL'         ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'WHILE'         ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'WRITE'         ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'DISPID'        ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'DIVIDE'        ;special:false;keyword:m_none;op:NOTOKEN), { delphi operator name }
      (str:'DOWNTO'        ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'EXCEPT'        ;special:false;keyword:m_except;op:NOTOKEN),
      (str:'EXPORT'        ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'HELPER'        ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'INLINE'        ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'LEGACY'        ;special:false;keyword:m_none;op:NOTOKEN),   { Syscall variation on MorphOS }
      (str:'NESTED'        ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'OBJECT'        ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'PACKED'        ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'PASCAL'        ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'PUBLIC'        ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'RECORD'        ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'REPEAT'        ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'RESULT'        ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'RETURN'        ;special:false;keyword:m_mac;op:NOTOKEN),
      (str:'SEALED'        ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'STATIC'        ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'STORED'        ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'STRICT'        ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'STRING'        ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'SYSTEM'        ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'ASMNAME'       ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'CPPDECL'       ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'DEFAULT'       ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'DYNAMIC'       ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'EXPORTS'       ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'FINALLY'       ;special:false;keyword:m_except;op:NOTOKEN),
      (str:'FORWARD'       ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'GENERIC'       ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'IOCHECK'       ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'LIBRARY'       ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'MESSAGE'       ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'MODULUS'       ;special:false;keyword:m_none;op:NOTOKEN), { delphi operator name }
      (str:'PACKAGE'       ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'PRIVATE'       ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'PROGRAM'       ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'R12BASE'       ;special:false;keyword:m_none;op:NOTOKEN),   { Syscall variation on MorphOS }
      (str:'RTLPROC'       ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'SECTION'       ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'STDCALL'       ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'SYSCALL'       ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'VARARGS'       ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'VIRTUAL'       ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'ABSOLUTE'      ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'ABSTRACT'      ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'BASESYSV'      ;special:false;keyword:m_none;op:NOTOKEN),   { Syscall variation on MorphOS }
      (str:'CONSTREF'      ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'CONTAINS'      ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'CONTINUE'      ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'CPPCLASS'      ;special:false;keyword:m_fpc;op:NOTOKEN),
      (str:'EXPLICIT'      ;special:false;keyword:m_none;op:NOTOKEN), { delphi operator name }
      (str:'EXTERNAL'      ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'FUNCTION'      ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'IMPLICIT'      ;special:false;keyword:m_none;op:NOTOKEN), { delphi operator name }
      (str:'LESSTHAN'      ;special:false;keyword:m_none;op:NOTOKEN), { delphi operator name }
      (str:'LOCATION'      ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'MULTIPLY'      ;special:false;keyword:m_none;op:NOTOKEN), { delphi operator name }
      (str:'MWPASCAL'      ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'NEGATIVE'      ;special:false;keyword:m_none;op:NOTOKEN), { delphi operator name }
      (str:'NOTEQUAL'      ;special:false;keyword:m_none;op:NOTOKEN), { delphi operator name }
      (str:'OPERATOR'      ;special:false;keyword:m_fpc;op:NOTOKEN),
      (str:'OPTIONAL'      ;special:false;keyword:m_none;op:NOTOKEN), { optional methods in an Objective-C protocol }
      (str:'OVERLOAD'      ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'OVERRIDE'      ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'PLATFORM'      ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'POSITIVE'      ;special:false;keyword:m_none;op:NOTOKEN), { delphi operator name }
      (str:'PROPERTY'      ;special:false;keyword:m_property;op:NOTOKEN),
      (str:'READONLY'      ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'REGISTER'      ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'REQUIRED'      ;special:false;keyword:m_none;op:NOTOKEN), { required methods in an Objective-C protocol }
      (str:'REQUIRES'      ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'RESIDENT'      ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'SAFECALL'      ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'SUBTRACT'      ;special:false;keyword:m_none;op:NOTOKEN), { delphi operator name }
      (str:'SYSVBASE'      ;special:false;keyword:m_none;op:NOTOKEN),   { Syscall variation on MorphOS }
      (str:'ASSEMBLER'     ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'BITPACKED'     ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'BITWISEOR'     ;special:false;keyword:m_none;op:NOTOKEN), { delphi operator name }
      (str:'INHERITED'     ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'INTDIVIDE'     ;special:false;keyword:m_none;op:NOTOKEN), { delphi operator name }
      (str:'INTERFACE'     ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'INTERRUPT'     ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'LEFTSHIFT'     ;special:false;keyword:m_none;op:NOTOKEN), { delphi operator name }
      (str:'LOGICALOR'     ;special:false;keyword:m_none;op:NOTOKEN), { delphi operator name }
      (str:'NODEFAULT'     ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'OBJCCLASS'     ;special:false;keyword:m_objectivec1;op:NOTOKEN),
      (str:'OTHERWISE'     ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'PROCEDURE'     ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'PROTECTED'     ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'PUBLISHED'     ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'REFERENCE'     ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'SOFTFLOAT'     ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'THREADVAR'     ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'WRITEONLY'     ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'BITWISEAND'    ;special:false;keyword:m_none;op:NOTOKEN), { delphi operator name }
      (str:'BITWISEXOR'    ;special:false;keyword:m_none;op:NOTOKEN), { delphi operator name }
      (str:'DEPRECATED'    ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'DESTRUCTOR'    ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'ENUMERATOR'    ;special:false;keyword:m_none;op:_OP_ENUMERATOR),
      (str:'IMPLEMENTS'    ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'INTERNPROC'    ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'LOGICALAND'    ;special:false;keyword:m_none;op:NOTOKEN), { delphi operator name }
      (str:'LOGICALNOT'    ;special:false;keyword:m_none;op:NOTOKEN), { delphi operator name }
      (str:'LOGICALXOR'    ;special:false;keyword:m_none;op:NOTOKEN), { delphi operator name }
      (str:'OLDFPCCALL'    ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'OPENSTRING'    ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'RIGHTSHIFT'    ;special:false;keyword:m_none;op:NOTOKEN), { delphi operator name }
      (str:'SPECIALIZE'    ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'CONSTRUCTOR'   ;special:false;keyword:m_all;op:NOTOKEN),
      (str:'GREATERTHAN'   ;special:false;keyword:m_none;op:NOTOKEN), { delphi operator name }
      (str:'INTERNCONST'   ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'REINTRODUCE'   ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'SHORTSTRING'   ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'COMPILERPROC'  ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'EXPERIMENTAL'  ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'FINALIZATION'  ;special:false;keyword:m_initfinal;op:NOTOKEN),
      (str:'NOSTACKFRAME'  ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'OBJCCATEGORY'  ;special:false;keyword:m_objectivec1;op:NOTOKEN), { Objective-C category }
      (str:'OBJCPROTOCOL'  ;special:false;keyword:m_objectivec1;op:NOTOKEN), { Objective-C protocol }
      (str:'WEAKEXTERNAL'  ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'DISPINTERFACE' ;special:false;keyword:m_class;op:NOTOKEN),
      (str:'UNIMPLEMENTED' ;special:false;keyword:m_none;op:NOTOKEN),
      (str:'IMPLEMENTATION';special:false;keyword:m_all;op:NOTOKEN),
      (str:'INITIALIZATION';special:false;keyword:m_initfinal;op:NOTOKEN),
      (str:'RESOURCESTRING';special:false;keyword:m_all;op:NOTOKEN),
      (str:'LESSTHANOREQUAL';special:false;keyword:m_none;op:NOTOKEN),    { delphi operator name }
      (str:'GREATERTHANOREQUAL';special:false;keyword:m_none;op:NOTOKEN)  { delphi operator name }
  );


var
  tokeninfo:ptokenarray;
  tokenidx:ptokenidx;

procedure inittokens;
procedure donetokens;
procedure create_tokenidx;


implementation

procedure create_tokenidx;
{ create an index with the first and last token for every possible token
  length, so a search only will be done in that small part }
var
  t : ttoken;
  i : longint;
  c : char;
begin
  fillchar(tokenidx^,sizeof(tokenidx^),0);
  for t:=low(ttoken) to high(ttoken) do
   begin
     if not arraytokeninfo[t].special then
      begin
        i:=length(arraytokeninfo[t].str);
        c:=arraytokeninfo[t].str[1];
        if ord(tokenidx^[i,c].first)=0 then
         tokenidx^[i,c].first:=t;
        tokenidx^[i,c].last:=t;
      end;
   end;
end;


procedure inittokens;
begin
  if tokenidx = nil then
  begin
    tokeninfo:=@arraytokeninfo;
    new(tokenidx);
    create_tokenidx;
  end;
end;


procedure donetokens;
begin
  if tokenidx <> nil then
  begin
    tokeninfo:=nil;
    dispose(tokenidx);
    tokenidx:=nil;
  end;
end;

end.
