Unit GC_IF; {Initial-Terminative Unit}
  interface
  Uses TPCRT, TPDOS, TPString, GCInter, GCTrace, GCProg;
  Var
    StartColor: byte;
    k, WC: integer;
    s, s1, s2: string;
    {t1: longint;}
  Procedure Load_Init;
  Procedure Terminate (key: char);
  implementation
  Procedure Load_Init;
    var
      c: char;
      i, j: integer;
      x, y: real;
    begin
{-------------------- Первоначальная обработка экрана -----------------------}
      WriteLn ('Расписание работы транспортной системы РТК гальванопокрытий',
               CRLF, 'Расчет расписания',
               CRLF, 'Межуев А., САПР, ТГТУ, 1992,94');
      SaveWindow(1,1,80,25,TRUE,StartScreen); StartColor:=TextAttr;
      Process:='2';
      If ParamCount<>0 then Process:=ParamStr(1);
{     Write ('Номер технологического процесса? '); ReadLn (Process);} 
      s:='shedule'+Process+'.dat';
      Assign (f_set, 'gcset.dat'); Reset (f_set);
      Read (f_set, i); Animation:=i=1;
{-------------------------- Ввод данных об автооператорах -------------------}
      Assign (f, 'autoop.dat'); ReSet (f);
      ReadLn (f, NumberOfRobots); ReadLn (f, x); ReadLn (f, y);
      RobotHorSpeed:=x/60; RobotVertSpeed:=y/60;
      ReadLn (f, HT);
      ReadLn (f, RobotStopTime[2]);
      ReadLn (f, RobotStopTime[1]);
      ReadLn (f, RobotStopTime[3]);
      VertTravelTime:=Round(HT/RobotVertSpeed);
      For i:=1 to NumberOfRobots do
        begin
        RobotZones[i]:=[];
        ReadLn(f, s1); WC:=WordCount(s1, [' ']);
        For k:=1 to WC do
          begin
          s2:=ExtractWord(k, s1, [' ']);
          c:=s2[Length(s2)];
          If c IN ['l', 'u'] then s2:=Copy(s2, 1, Length(s2)-1);
          Str2Int(s2, j);
          RobotZones[i]:=RobotZones[i]+[j];
          Case c of
            'l': LoadPosition:=j;
            'u': UnloadPosition:=j;
          end;
          end;
        end;
      Close (f);
{-------------------- Ввод данных о технологических процесах ----------------}
      Assign (f, 'process.dat'); ReSet (f);
      ReadLn(f, NumberOfSupportOp);
      For i:=1 to NumberOfSupportOp do with SupportOp[i] do
        begin
        ReadLn(f, c, PRTY, x, x, s1); Pos:=0; Name:=Trim(s1);
        end;
      StartCharge:=CharStr('F', NumberOfSupportOp);
      Close (f);
      Assign (f, 'vanna.dat'); ReSet (f);
{--------------------------- Ввод данных о позициях --------------------------}
      ReadLn (f, NumberOfPositions); ReadLn (f);
      P[1].Coord:=0;
      For i:=2 to NumberOfPositions do
        begin ReadLn (f, x); P[i].Coord:=P[i-1].Coord+x/1000; end;
      ReadLn (f);
      For i:=1 to NumberOfPositions do
        begin
        P[i].Value:=0;
{$IFDEF Graphic}
        PositionImage[i].NumberOfOp:=0;
{$ENDIF}
        Read (f, P[i].Colour, j);
        While j<>0 do
          begin
            if SupportOp[j].Pos=0 then SupportOp[j].Pos:=i; Read (f, j);
{$IFDEF Graphic}
            inc(PositionImage[i].NumberOfOp);
{$ENDIF}
          end;
        ReadLn (f, j); inc (P[j].Value);
        end;
      Close (f);
{----------------- Ввод данных о регламенте обработки деталей ---------------}
      Assign (f, s); ReSet (f);
      j:=0;
      Repeat
        inc(j);
        ReadLn(f);
        With D[j] do
          begin
            Oper.Pos:=0; Oper.MinDuration:=0; Start:=0; Stage:=0;
            ReglBreach[0]:=0; C:=1;
          end;
        Op[j,0].Pos:=0;
        i:=1;
        Repeat
          With Op[j,i] do
            begin
              readln (f, Number, x, y); Pos:=SupportOp[Number].Pos;
              MinDuration:=Round(x*60); MaxDuration:=Round(y*60);
            end;
          inc (i); Read(f, c);
        until c IN ['C', 'D'];
        Op[j,MaxStages+1].Pos:=i-1;
      until c='C';
      D[0]:=D[1];
      NumberOfDetails:=j;
      ReadLn (f);
{close(f);assign(f,'shed_or'+Process+'.dat');reset(f);}
      For i:=1 to NumberOfDetails do
        with Charge[i] do
          begin
          Read (f, x, Det); MinTimeFromPrevious:=Round(x*60); Start:=0;
          end;
      Charge[0]:=Charge[NumberOfDetails];
      Close(f);
{----------------------------- Чтение настройки -----------------------------}
      Read (f_set, State, i, TimeScale, DelayTime, DelayTimeMin);
      AutoTimeRegime:=i=1;
      Close(f_set);
{                        Инициализация состояний объектов                    }
      OFVT[0]:=0; T0:=0; P0:=1;
      For i:=1 to MaxRS do begin P[i].Fillness:=0; P[i].ContDet:=0; end;
      Time:=0; TimeInc:=0; Cycle:=1;
      For i:=1 to NumberOfRobots do
        with R[i] do
          begin
          HorCoord:=0; VertCoord:=-1; HorDir:=0; VertDir:=0; WithLoad:=FALSE;
          SSTime:=0; DestP:=0; Busy:=FALSE; Element:=0; RestTravelTime:=0;
          RestStopVertTravelTime:=0;
          end;
r[1].horcoord:=p[1].coord; r[2].horcoord:=p[13].coord;
      For i:=1 to NumberOfRobots do
        with CC[i] do
          begin
          Det:=1; SourcePos:=0; DestPos:=0; CurrentAimPos:=0;
          end;
      InitScreen(Animation);
      TraceProgram(0, 0, ' ', 0, 0, 0);
      CalcTimeParm[1]:=TimeMs; CalcTimeParm[3]:=0;
    end;
{ Загрузка операций для каждой детали; инициализация состояний объектов }

  Procedure Terminate (key: char);
    begin
      CalcTimeParm[2]:=TimeMs;
      TraceTerminate;
      If DelayTimeMin=1 then
        DelayTimeMin:=Round((CalcTimeParm[2]-CalcTimeParm[1])/CalcTimeParm[3]);
      Rewrite (f_set);
      If AutoTimeRegime then TimeScale:=1;
      Write (f_set, ord(Animation), State:2,        ord(AutoTimeRegime):2,
                    TimeScale:9:2,  DelayTimeMin:4, DelayTimeMin:4);
      Close (f_set);
{write ((TimeMs-t1)/1000:8:2);}
      Halt;
    end;
begin {t1:=TimeMs;} end.
