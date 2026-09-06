(*  §à ¡®âª   «£®à¨â¬®¢ ã¯à ¢«¥­¨ï âà ­á¯®àâ­®© á¨áâ¥¬®© ’Š £ «ì- *)
(* ¢ ­®¯®ªàëâ¨© á ¨á¯®«ì§®¢ ­¨¥¬  ¬¥â®¤®¢ á¨âã æ¨®­­®£® ã¯à ¢«¥­¨ï. *)
(* “â®ç­¥­¨¥ ¨­â¥à¢ «®¢ ¬¥¦¤ã § ¯ãáª ¬¨ ¤¥â «¥© ¢ ®¡à ¡®âªã         *)

{$M $4000,0,20000}
program The_Coordinate_Lowering;
  uses DOS, TPCRT;
  const
    MaxD=7;
  type
    vector=array [1..MaxD] of real;
  var
flag: boolean;
    i, j, D, Sign, St: integer;
int_i,N: longint;
    h, E, xh, z1, z2: real;
    c: char;
    FN, Process, s: string;
    f, f1, f2: text;
    x: vector;
    ChargedDet: array [1..MaxD] of byte;

  function Z (var x: vector): real;
    const k=1E-3;
    var
      i: byte;
      OFVT, Time: longint;
      s: string;
      SC: Pointer;
    begin
      Rewrite(f2);
      For i:=1 to D do write(f2, x[i]:7:1, ChargedDet[i]:3);
      Close(f2);

      SaveWindow(1,1,80,25,TRUE,SC); i:=TextAttr;
      Exec('gc.exe', '');
      TextAttr:=i; RestoreWindow(1,1,80,25,TRUE,SC); Window (1,3,80,25);
      Reset(f1); Repeat ReadLn(f1); Read(f1, c) until c='®';
      Repeat Read(f1, c) until c=':';
      ReadLn(f1, OFVT);
      ReadLn(f1);
      Repeat Read(f1, c) until c=':'; ReadLn(f1, Time);
      Z:=OFVT+k*Time;
      Close(f1);
    end;
  begin       flag:=false;
{???}
    ClrScr;
{   Write ('®¬¥à â¥å­®«®£¨ç¥áª®£® ¯à®æ¥áá ? '); ReadLn (Process);} Process:='1';
    FN:='shedule'+Process+'.dat';
    D:=0;
    Assign(f, FN); Reset(f);
    Assign(f1,'program'+Process+'.dat');
    Assign(f2,'shed_or'+Process+'.dat');
    Repeat ReadLn(f, c); If c='D' then inc(D); until c='C';
    For i:=1 to D do Read(f, x[i], ChargedDet[i]); Close(f);
{   Write ('Step?                '); ReadLn (h);   }    h:=10;
{   Write ('Precision?           '); ReadLn (E);   }    E:=0.01;
{   Write ('Step of trace?       '); ReadLn (St);  }    St:=1;
    ClrScr;
    Write ('   N    h'); For i:=1 to D do write('x':6,i:1); write('f':7);
    N:=0; z1:=Z(x);
    While h>E do
      begin
        if N mod St=0 then
          begin
            GoToXY(1,N mod 24);
            Write (N:4,' ', h:6:3, ' ');
            For j:=1 to D do Write (x[j]:6:1, ' ');
            WriteLn (z1:8:2, ' ');
          end;
        For i:=2 to D do
          begin
            ChangeAttribute(2, 1, 8+7*i, $8F);
            xh:=x[i]; x[i]:=x[i]+h; z1:=Z(x); x[i]:=xh; z2:=Z(x);
            If z1>z2 then Sign:=-1 else Sign:=1;
int_i:=0;
            Repeat
str(int_i,s);fastwrite(s, 1, 11+7*i, $0F);inc(int_i);
              xh:=x[i]; z1:=z2;
              x[i]:=x[i]+Sign*h; z2:=Z(x);
if z1=z2 then begin h:=h*2;flag:=true;end;
            Until z2>z1;
            x[i]:=xh;
            ChangeAttribute(2, 1, 8+7*i, 7); fastwrite('  ',1,11+7*i, 7);
if flag then begin flag:=false; h:=h/2;end;
          end;
        inc(N);
        h:=h/2;
      end;
    Write ('Function`s minimum ', z1:7:4, ' in the point with coordinates:');
    For j:=1 to D do Write (x[j]:7:4, ' ');
    Write (#10,#13,'was found by ', N, ' iterations');
end.
