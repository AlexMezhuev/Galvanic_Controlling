Unit GCProg;
  interface
  Uses GCInter, GCState;
  Procedure TraceProgram(Fun, NR: byte; C: char; DT: longint; B, D0: byte);
  implementation

  Procedure TraceProgram(Fun, NR: byte; C: char; DT: longint; B, D0: byte);
    type
      SAdtype=record Com1: ProgramList; Len: word; Code: byte; end;
    var
      CycleDuration: longint;
      SAd: array [1..MaxRobots] of SAdtype;

    Procedure InitPrograms(Fun, NumberOfRobots: byte; C: char; DT: longint; B, D0: byte);
      var
        i: byte;
      begin                    { ¨­¨æ¨ «¨§ æ¨ï á¯¨áª®¢ }
        For i:=1 to NumberOfRobots do
          TraceProgram(1, i, C, DT, RobotCoordInPos(i,delta), D0);
        New(B_NewEl); B_NewEl^.Next:=NIL; B_Left:=B_NewEl; B_Right:=B_NewEl;
      end;

    Procedure AddCommand(Fun, NR: byte; C: char; DT: longint; B, D0: byte);
      begin  { § ¯¨áì ª®¬ ­¤ë: ¯¥à¢®© (Fun=1) ¨ ¢á¥å ®áâ «ì­ëå (Fun=2) }
      {If (D[CC[NR].Det].C<=4) OR (C='k') OR (Fun=1) then begin}
        If (c='c') AND (DT=0) then Exit;
        New(NewEl[NR]); If Fun=2 then Right[NR]^.Next:=NewEl[NR];
        With NewEl[NR]^ do
          begin
          Next:=NIL; Command:=c; DelayTime:=DT; Pos:=B; Detail:=D0;
{$R-}     Stage:=D[CC[NR].Det].Stage; {$R+}
          end;
        If Fun=1 then Left[NR]:=NewEl[NR];
        Right[NR]:=NewEl[NR];
        {end;}
      end;

    Procedure AddBreach(Fun, NR: byte; C: char; DT: longint; B, D0: byte);
      begin
      If D[D0].C=1 then
        begin               { § ¯¨áì ¢ á¯¨á®ª ­ àãè¥­¨© }
        New(B_NewEl); B_Right^.Next:=B_NewEl;
        With B_NewEl^ do
          begin
          Next:=NIL;
          Det:=D0; Pos:=B; exceedence:=DT;
          percent:=exceedence/D[D0].Oper.MaxDuration*100;
          end;
        B_Right:=B_NewEl;
        end;
      end;

    Procedure ProcessShedule(Fun, NR: byte; C: char; DT: longint; B, D0: byte);
      var
        i: byte;
        Len1: word;
        TimeDec: longint;
        Com, Com1_prev, SAd1, SAdi: ProgramList;
        WasTaken: array [1..MaxRS] of boolean;

      Function RobotCycle(NR: byte; var Com1_prev, Com1: ProgramList; var Len: word): byte;
        var               { ®¯â¨¬¨§ æ¨ï ¯à¨ ãç¥â¥ ¤«¨­ë à á¯¨á ­¨ï }
          flag: boolean;
          i: byte;
          El2, El3, El4, El_tmp, SAd1: ProgramList;
        begin {                     ®¨áª æ¨ª«  ã à®¡®â  NR                  }
        El_tmp:=Left[NR]^.Next;
        Repeat
          Com1_prev:=Com1; { ã¤ «¥­¨¥ Com1 }
          Com1:=El_tmp;
          El2:=Com1;
          flag:=FALSE;
{$B-}     Repeat
            El2:=El2^.Next;
            If ((Com1^.DelayTime=El2^.DelayTime) AND (Com1^.Pos=El2^.Pos)) then
              begin
              El3:=Com1; El4:=El2; Len:=0;
{$B+}         Repeat
                El3:=El3^.Next; El4:=El4^.Next; inc(Len);
                flag:=(El3^.DelayTime<>El4^.DelayTime) OR (El3^.Pos<>El4^.Pos)OR
                      ((El4^.DelayTime=Com1^.DelayTime) AND (El4^.Pos=Com1^.Pos))
                      OR(El4^.Next=NIL);
              until flag;
              end;
          until flag OR (El2^.Next=NIL);
          El_tmp:=Com1^.Next;
        Until ((El3^.DelayTime=El4^.DelayTime) AND (El3^.Pos=El4^.Pos)  AND
              (El4^.DelayTime=Com1^.DelayTime) AND (El4^.Pos=Com1^.Pos))
              OR (El_tmp^.Next=NIL);
        If El_tmp^.Next=NIL
          then begin RobotCycle:=1; Len:=0; end
          else begin RobotCycle:=0; CycleDuration:=El2^.t0-Com1^.t0; end;
      end;

      begin
      If Charge[1].MinTimeFromPrevious<>0 then
        with SAd[1] do   {               ®¨áª æ¨ª«  ã à®¡®â  NR             }
          begin
          Code:=RobotCycle(1, Com1_prev, Com1, Len);
          If Code=1 then
            begin { æ¨ª« ­¥ ­ ©¤¥­ } end
                    else
            begin {        II. ®¨áª § å¢ â  ¤¥â «¨ á ¯®§¨æ¨¨ § £àã§ª¨       }
            If Com1_prev^.Pos<>LoadPosition then
              begin
              While Com1^.Pos<>LoadPosition do Com1:=Com1^.Next;
              Com1:=Com1^.Next;
              end;
{            III. ®¨áª æ¨ª«®¢ ã ®áâ «ì­ëå à®¡®â®¢ ¨ ª®àà¥ªâ¨à®¢ª            }
            For NR:=2 to NumberOfRobots do
              with SAd[NR] do 
                begin
                Code:=RobotCycle(NR, Com1_prev, Com1, Len);
                If Code=0 then
                  begin
                  SAd1:=SAd[1].Com1;
                  While Com1^.t0>SAd1^.t0 do
                    for i:=1 to SAd[1].Len do SAd1:=SAd1^.Next;
                  TimeDec:=SAd1^.t0;
                  SAdi:=Com1; Len1:=1;
                  While ((SAdi^.t1>TimeDec) OR (SAdi^.Next^.t0<TimeDec)) AND
                        (Len1<=Len)
                    do begin SAdi:=SAdi^.Next; inc(Len1); end;
                  Com1:=SAdi^.Next;
                  If (Len1>Len)OR(Com1^.Detail<>0) then Code:=2
                              else
                    begin
                    Com1^.DelayTime:=Com1^.t0-TimeDec;
                    inc(Len);
                    For i:=1 to Len do SAdi:=SAdi^.Next;
                    dec(SAdi^.DelayTime, Com1^.DelayTime);
                    end;
                  end;
                end;
{               IV. Ž¯à¥¤¥«¥­¨¥ ¯®§¨æ¨© ­ ç «ì­ëå § £àã§®ª                   }
{ Error may be occurs when analizing 12th (trans) position }
            StartCharge[1]:='T';
            For i:=1 to NumberOfPositions do WasTaken[i]:=FALSE;
            For NR:=1 to NumberOfRobots do
              begin
              Com:=SAd[NR].Com1; i:=1;
              While i<SAd[NR].Len do
                begin
{$B-}           While (Com^.Detail<>0) AND (i<SAd[NR].Len) do
                  begin WasTaken[Com^.Pos]:=TRUE; Com:=Com^.Next; inc(i); end;
                If (Com^.Detail=0) AND (i<SAd[NR].Len) then
                  while Com^.Detail=0 do
                    begin Com1_prev:=Com; Com:=Com^.Next; inc(i); end;
                If Com^.Detail<>0 then with Com1_prev^ do
                  if Not WasTaken[Pos] then
                    begin StartCharge[Pos]:='T'; WasTaken[Pos]:=TRUE; end;
                end;
              end;
            end;
          end;
    end;

    Procedure WritePrograms(Fun, NR: byte; C: char; DT: longint; B, D0: byte);
      var
        i: byte;
      begin
      If Cycle =4 then
        begin                     { § ¯¨áì á¯¨áª®¢ ¢ ä ©« }
        ProcessShedule(4, NR, C, DT, B, D0);
        Assign (f, 'program'+Process+'.dat'); ReWrite(f); WriteLn (f, StartCharge);
        If Charge[1].MinTimeFromPrevious=0 then
          begin
          For i:=1 to NumberOfRobots do
            begin
            TraceProgram(2, i, 'k', DT-R[i].SSTime, 255, 0);
            NewEl[i]:=Left[i]^.Next;
            WriteLn (f, i:1, '-©  ¢â®®¯¥à â®à');
            While NewEl[i]<>NIL do
              With NewEl[i]^ do
                begin
                Write (f, Command, DelayTime:6);
write(f,t0:6);
If Command in [' ','K'] then write(f, Pos:4) else write(f);
                If Detail<>0 then Write{Ln} (f, Detail:3, Stage:4) else Write{Ln}(f);
writeLn(f,t1:6);

                NewEl[i]:=NewEl[i]^.Next;
                end;
            end;
{             Write (f, 'à¥¢ëè¥­¨ï à¥£« ¬¥­â :', #10, '®¡é¥¥: ', OFVT[Cycle-1]:1,
                 #10, '¯® ¤¥â «ï¬: ');
          For i:=1 to NumberOfDetails do Write (f, D[i].ReglBreach[Cycle-1]:1, ' ');
          If OFVT[Cycle-1]<>0 then
            begin
            WriteLn (f, #10+'„¥â «ì  ®§¨æ¨ï      à¥¢ëè¥­¨¥ (á¥ª, %)');
            B_NewEl:=B_Left^.Next;
            While B_NewEl<>NIL do
              With B_NewEl^ do
                begin
                WriteLn (f, Det:3, Pos:10, exceedence:15, percent:7:1);
                B_NewEl:=B_NewEl^.Next;
                end;
            end;
}             Write (f, #10, 'à®¤®«¦¨â¥«ì­®áâì ¯à®æ¥áá : ', Time:1);
          end
                                           else
          begin
          For NR:=1 to NumberOfRobots do
            with SAd[NR] do
              begin
              WriteLn (f, NR:1, '-©  ¢â®®¯¥à â®à');
              Case Code of
                0: For i:=1 to Len do with Com1^ do
                     begin
                     Write (f, Command, DelayTime:6, Pos:4);
                     If Detail<>0 then WriteLn (f, '1':3) else WriteLn (f);
                     Com1:=Com1^.Next;
                     end;
                1: WriteLn (f, 'Žè¨¡ª : –¨ª« ­¥ ®¡­ àã¦¥­');
                2: WriteLn (f, 'Žè¨¡ª : ‘¨­åà®­¨§ æ¨ï ­¥¢®§¬®¦­ ');
              end;
              end;
          WriteLn (f, '„«¨â¥«ì­®áâì æ¨ª« : ', CycleDuration:1);
          end;
        Close(f);
      end;
    end;

    begin
      Case Fun of
        0:  InitPrograms(Fun, NR, C, DT, B, D0);
        1,2:AddCommand(Fun, NR, C, DT, B, D0);
        3:  AddBreach(Fun, NR, C, DT, B, D0);
        255:WritePrograms(Fun, NR, C, DT, B, D0);
      end;
    end;
{ ‡ ¯¨áì à á¯¨á ­¨© ¤¢¨¦¥­¨© à®¡®â®¢ }

begin end.
