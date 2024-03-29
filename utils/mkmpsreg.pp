{
    Copyright (c) 1998-2002 by Peter Vreman and Florian Klaempfl

    Convert mipsreg.dat to several .inc files for usage with
    the Free pascal compiler

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
{$mode objfpc}
program mkmipsreg;

const Version = '1.00';
      max_regcount = 200;

var s : string;
    i : longint;
    line : longint;
    regcount:byte;
    regcount_bsstart:byte;
    names,
    regtypes,
    supregs,
    numbers,
    stdnames,
    gasnames,
    dwarfs,
    stabs : array[0..max_regcount-1] of string[63];
    regnumber_index,
    std_regname_index,
    gas_regname_index : array[0..max_regcount-1] of byte;

function tostr(l : longint) : string;

begin
  str(l,tostr);
end;

function readstr : string;

  begin
     result:='';
     while (s[i]<>',') and (i<=length(s)) do
       begin
          result:=result+s[i];
          inc(i);
       end;
  end;


procedure readcomma;
  begin
     if s[i]<>',' then
       begin
         writeln('Missing "," at line ',line);
         writeln('Line: "',s,'"');
         halt(1);
       end;
     inc(i);
  end;


procedure skipspace;

  begin
     while (s[i] in [' ',#9]) do
       inc(i);
  end;

procedure openinc(out f:text;const fn:string);
begin
  writeln('creating ',fn);
  assign(f,fn);
  rewrite(f);
  writeln(f,'{ don''t edit, this file is generated from mipsreg.dat }');
end;


procedure closeinc(var f:text);
begin
  writeln(f);
  close(f);
end;

procedure build_regnum_index;

var h,i,j,p,t:byte;

begin
  {Build the registernumber2regindex index.
   Step 1: Fill.}
  for i:=0 to regcount-1 do
    regnumber_index[i]:=i;
  {Step 2: Sort. We use a Shell-Metzner sort.}
  p:=regcount_bsstart;
  repeat
    for h:=0 to regcount-p-1 do
      begin
        i:=h;
        repeat
          j:=i+p;
          if numbers[regnumber_index[j]]>=numbers[regnumber_index[i]] then
            break;
          t:=regnumber_index[i];
          regnumber_index[i]:=regnumber_index[j];
          regnumber_index[j]:=t;
          if i<p then
            break;
          dec(i,p);
        until false;
      end;
    p:=p shr 1;
  until p=0;
end;

procedure build_std_regname_index;

var h,i,j,p,t:byte;

begin
  {Build the registernumber2regindex index.
   Step 1: Fill.}
  for i:=0 to regcount-1 do
    std_regname_index[i]:=i;
  {Step 2: Sort. We use a Shell-Metzner sort.}
  p:=regcount_bsstart;
  repeat
    for h:=0 to regcount-p-1 do
      begin
        i:=h;
        repeat
          j:=i+p;
          if stdnames[std_regname_index[j]]>=stdnames[std_regname_index[i]] then
            break;
          t:=std_regname_index[i];
          std_regname_index[i]:=std_regname_index[j];
          std_regname_index[j]:=t;
          if i<p then
            break;
          dec(i,p);
        until false;
      end;
    p:=p shr 1;
  until p=0;
end;


procedure build_gas_regname_index;

var h,i,j,p,t:byte;

begin
  {Build the registernumber2regindex index.
   Step 1: Fill.}
  for i:=0 to regcount-1 do
    gas_regname_index[i]:=i;
  {Step 2: Sort. We use a Shell-Metzner sort.}
  p:=regcount_bsstart;
  repeat
    for h:=0 to regcount-p-1 do
      begin
        i:=h;
        repeat
          j:=i+p;
          if gasnames[gas_regname_index[j]]>=gasnames[gas_regname_index[i]] then
            break;
          t:=gas_regname_index[i];
          gas_regname_index[i]:=gas_regname_index[j];
          gas_regname_index[j]:=t;
          if i<p then
            break;
          dec(i,p);
        until false;
      end;
    p:=p shr 1;
  until p=0;
end;


procedure read_mipsreg_file;

var infile:text;

begin
   { open dat file }
   assign(infile,'mipsreg.dat');
   reset(infile);
   while not(eof(infile)) do
     begin
        { handle comment }
        readln(infile,s);
        inc(line);
        while (s[1]=' ') do
         delete(s,1,1);
        if (s='') or (s[1]=';') then
          continue;

        i:=1;
        names[regcount]:=readstr;
        readcomma;
        regtypes[regcount]:=readstr;
        readcomma;
        supregs[regcount]:=readstr;
        readcomma;
        stdnames[regcount]:=readstr;
        readcomma;
        gasnames[regcount]:=readstr;
        readcomma;
        stabs[regcount]:=readstr;
        readcomma;
        dwarfs[regcount]:=readstr;
        { Create register number }
        if supregs[regcount][1]<>'$' then
          begin
            writeln('Missing $ before number, at line ',line);
            writeln('Line: "',s,'"');
            halt(1);
          end;
        numbers[regcount]:=regtypes[regcount]+'0000'+copy(supregs[regcount],2,255);
        if i<length(s) then
          begin
            writeln('Extra chars at end of line, at line ',line);
            writeln('Line: "',s,'"');
            halt(1);
          end;
        inc(regcount);
        if regcount>max_regcount then
          begin
            writeln('Error: Too much registers, please increase maxregcount in source');
            halt(2);
          end;
     end;
   close(infile);
end;

procedure write_inc_files;

var
    norfile,stdfile,supfile,
    numfile,stabfile,confile,gasfile,dwarffile,
    rnifile,srifile,grifile : text;
    first:boolean;

begin
  { create inc files }
  openinc(confile,'rmipscon.inc');
  openinc(supfile,'rmipssup.inc');
  openinc(numfile,'rmipsnum.inc');
  openinc(stdfile,'rmipsstd.inc');
  openinc(gasfile,'rmipsgas.inc');
  openinc(stabfile,'rmipssta.inc');
  openinc(dwarffile,'rmipsdwf.inc');
  openinc(norfile,'rmipsnor.inc');
  openinc(rnifile,'rmipsrni.inc');
  openinc(srifile,'rmipssri.inc');
  openinc(grifile,'rmipsgri.inc');
  first:=true;
  for i:=0 to regcount-1 do
    begin
      if not first then
        begin
          writeln(numfile,',');
          writeln(stdfile,',');
          writeln(gasfile,',');
          writeln(stabfile,',');
          writeln(dwarffile,',');
          writeln(rnifile,',');
          writeln(srifile,',');
          writeln(grifile,',');
        end
      else
        first:=false;
      writeln(supfile,'RS_',names[i],' = ',supregs[i],';');
      writeln(confile,'NR_'+names[i],' = ','tregister(',numbers[i],')',';');
      write(numfile,'tregister(',numbers[i],')');
      write(stdfile,'''',stdnames[i],'''');
      write(gasfile,'''',gasnames[i],'''');
      write(stabfile,stabs[i]);
      write(dwarffile,dwarfs[i]);
      write(rnifile,regnumber_index[i]);
      write(srifile,std_regname_index[i]);
      write(grifile,gas_regname_index[i]);
    end;
  write(norfile,regcount);
  close(confile);
  close(supfile);
  closeinc(numfile);
  closeinc(stdfile);
  closeinc(gasfile);
  closeinc(stabfile);
  closeinc(dwarffile);
  closeinc(norfile);
  closeinc(rnifile);
  closeinc(srifile);
  closeinc(grifile);
  writeln('Done!');
  writeln(regcount,' registers procesed');
end;


begin
   writeln('Register Table Converter Version ',Version);
   line:=0;
   regcount:=0;
   read_mipsreg_file;
   regcount_bsstart:=1;
   while 2*regcount_bsstart<regcount do
     regcount_bsstart:=regcount_bsstart*2;
   build_regnum_index;
   build_std_regname_index;
   build_gas_regname_index;
   write_inc_files;
end.
