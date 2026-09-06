(* Разработка алгоритмов управления транспортной системой РТК галь- *)
(* ванопокрытий с использованием  методов ситуационного управления. *)
(* Управление микроконтроллером                                     *)
Program MicroController;
  Uses TPCRT, TPDate, TPDOS, TPString, GCInter, GCProg;
  Type
    RobotStateType1=object (RobotStateType)
      Stage: byte;
    end;
  Var
    NR: byte;
    R: array [1..MaxRobots] of RobotStateType1;

  Procedure SendByte(B: byte);
    var T0: longint;
    begin
      Mem[$0000:$0400]:=B;
      T0:=TimeMs;
      Repeat until (Mem[$0000:$0400]=B) OR (TimeMs-T0>5);
      If Mem[$0000:$0400]<>B then
        begin
        FastWrite ('Ошибка передачи данных', WhereX, WhereY, $1E); Halt;
        end;
    end;

  Function ReceiveByte: byte;
    begin
      ReceiveByte:=Mem[$0000:$0400];
    end;

  Procedure SendCommand(Operation, Operand: byte);
    begin
      SendByte($4B);
      SendByte(Operation);
      SendByte(Operand);
      SendByte(0); SendByte(0);
    end;

  Procedure Init;
    var
      i: byte;
      s: string;
    begin
{-------------------- Первоначальная обработка экрана -----------------------}
      WriteLn ('Расписание работы транспортной системы РТК гальванопокрытий',
               CRLF, 'Управление микроконтроллером',
               CRLF, 'Межуев А., САПР, ТГТУ, 1992,94');
      SaveWindow(1,1,80,25,TRUE,StartScreen); StartColor:=TextAttr;
{---------------------- Ввод номера файла расписания ------------------------}
      Process:='2';
      If ParamCount<>0 then Process:=ParamStr(1);
    {     Write ('Номер файла расписания? '); ReadLn (Process);}
{-------------------- Инициализация состояний роботов ----------------------}
      For i:=1 to NumberOfRobots do
        with R[i] do
          begin
          HorCoord:=0; VertCoord:=-1; HorDir:=0; VertDir:=0;
          SSTime:=0; DestP:=0; Element:=-1; RestTravelTime:=0;
          RestStopVertTravelTime:=0;
          end;
r[1].horcoord:=1; r[2].horcoord:=13;
{--------------------- Инициализация микроконтроллера -----------------------}
      SendByte($4A);
      SendByte($01);
      SendByte(0); SendByte(0);
  end;

  Procedure ReadPrograms;
    var
      Finish: boolean;
      i: byte;
      N: longint;
      S: string;
    begin
      Assign (f, 'program'+Process+'.dat'); ReSet(f); ReadLn (f, StartCharge);
      For i:=1 to MaxRobots do TraceProgram(1, i, ' ', 0, 0, 0);
      NR:=0;
      Repeat
        ReadLn (f, S);
        Finish:=(Pos(':', S)<>0) OR (Trim(S)='');
         If Not Finish then
          begin
          If Pos('автооператор', S)<>0 then
            begin
            If NR<>0 then NewEl[NR]:=Left[NR];
            inc(NR);
            ReadLn (f, S);
            If Pos('Превышения', S)<>0 then Exit;
            If Pos('Ошибка', S)<>0 then Halt;
            NewEl[NR]:=Left[NR];
            end;
          New(NewEl[NR]); Right[NR]^.Next:=NewEl[NR];
          With NewEl[NR]^ do
            begin
            Next:=NIL;
            Command:=S[1]; Pos:=0; Detail:=0;
            S:=Copy(S, 2, Length(S)-1);
            For i:=1 to WordCount(S, [' ']) do
              begin
              Str2Long(ExtractWord(i, S, [' ']), N);
              Case i of
                1: DelayTime:=N;
                2: Pos:=N;
                3: Detail:=N;
              end;
              end;
            end;
          Right[NR]:=NewEl[NR];
          end
                       else
          NewEl[NR]:=Left[NR];
      Until Finish;
      Close(f);
      NumberOfRobots:=NR;
    end;

  Procedure Plug (Contact: byte);
    begin
      SendCommand($05, Contact);
    end;

  Procedure Unplug (Contact: byte);
    begin
      SendCommand($06, Contact);
    end;

  Function Transducer(TD: byte): byte;
    begin
      SendCommand($1E, TD);
      SendByte($49);
      SendByte($FF); SendByte($04);
      SendByte($00); SendByte($01);
      SendByte(0); SendByte(0);
      If ReceiveByte=0 then Transducer:=0 else Transducer:=1;
      ReceiveByte; ReceiveByte;
    end;

  Procedure RobotStep_Init(NR: byte);
    begin
      NewEl[NR]:=NewEl[NR]^.Next;
      With R[NR] do
        begin
        Element:=0;
        RestStopVertTravelTime:=NewEl[NR]^.DelayTime;
        SSTime:=CurrentTime; { ? }
        end;
    end;

  Procedure RobotStep_Stop(NR: byte);
    begin
      With R[NR] do
        if CurrentTime-SSTime>=RestStopVertTravelTime then
          begin
          inc(Element);
          RestStopVertTravelTime:=0;
          Case Element of
            1,5: If NewEl[NR]^.Command='c' then Element:=-1 else
                   begin
                   DestP:=NewEl[NR]^.Pos;
                   If HorCoord<DestP then HorDir:=1 else HorDir:=-1;
                   Stage:=1;
                   end;
            3:   If NewEl[NR]^.Detail<>0
                   then begin VertDir:=1; Stage:=1; end else Element:=-1;
            7:   begin
                 VertDir:=-1;
                 Stage:=1;
                 end
          end
          end
    end;

  Procedure RobotStep_Hor(NR: byte);
    var Contact: byte;
    begin
      Contact:=(NR-1)*2; If R[NR].HorDir=1 then inc(Contact);
      With R[NR] do
        if Stage=1 then
          begin
          Plug(Contact);
          inc(Stage);
          end
                   else
          if Transducer(DestP-1)=1 then
            begin
            Unplug(Contact);
            HorCoord:=DestP;
            HorDir:=0;
            inc(Element);
            RestStopVertTravelTime:=RobotStopTime[Element div 2];
            Stage:=0;
            SSTime:=CurrentTime;
            end;
    end;

  Procedure RobotStep_Vert(NR: byte);
    var Contact: byte;
    begin
      With R[NR] do
        if Stage=1 then
          begin
          Contact:=(NR-1)*2+NumberOfRobots*2; If VertDir=1 then inc(Contact);
          Plug(Contact);
          inc(Stage);
          end
                   else
          begin
          Contact:=MaxRS+(NR-1)*2; If VertDir=1 then inc(Contact);
          If Transducer(Contact)=1 then
            begin
            Contact:=(NR-1)*2+NumberOfRobots*2; If VertDir=1 then inc(Contact);
            Unplug(Contact);
            If VertDir=-1 then VertCoord:=-1 else VertCoord:=1;
            VertDir:=0;
            If Element=3 then
              begin
              inc(Element);
              RestStopVertTravelTime:=RobotStopTime[2];
              SSTime:=CurrentTime;
              end
                         else
              Element:=-1;
            end
          end
    end;

  Procedure Control;
    var Term: boolean;
    begin
      Term:=TRUE;
      Repeat
        For NR:=1 to NumberOfRobots do
          With R[NR] do
            Case Element of
              -1:       RobotStep_Init(NR);
               0,2,4,6: RobotStep_Stop(NR);
               1,5:     RobotStep_Hor(NR);
               3,7:     RobotStep_Vert(NR);
            end;
{$B-} Term:=Term AND (NewEl[NR]^.Next=NIL) AND (R[NR].Element=-1); {$B+}
      Until Term;
  end;

  Procedure Terminate;
    begin
      RestoreWindow(1,1,80,25,TRUE,StartScreen);
      TextAttr:=StartColor;
  end;

  begin
    Init;
    ReadPrograms;
    Control;
    Terminate;
end.