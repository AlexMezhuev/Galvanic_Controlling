Unit GCCtrl;
  interface
  Uses TPCRT, GCInter, GC_IF, GCMenu, GCState, GCTrace, GCProg;
  Var
    exceedence, TimeQuantum: longint;
  Procedure Control;
  implementation
  Procedure TakeDetail(CarryCommand: CarryCommandType);
    begin
      With CarryCommand do
      begin
      dec (P[SourcePos].Fillness); P[CurrentAimPos].ContDet:=0;
      If Detail(Det, timeD)=Critical then
        begin
        exceedence:=timeD-D[Det].Oper.MaxDuration;
        inc(D[Det].ReglBreach[Cycle-D[Det].C], exceedence);
        inc(OFVT[Cycle-D[Det].C], exceedence);
        TraceProgram(3, 0, ' ', exceedence, SourcePos, Det);
        end;
      end;
    end;

  Procedure PutDetail(CarryCommand: CarryCommandType);
    begin
      With D[CarryCommand.Det] do
        begin
        inc (Stage);
        Oper:=Op[CarryCommand.Det, Stage]; Oper.Pos:=CarryCommand.CurrentAimPos;
        Start:=Time;
        end;
      With CarryCommand do
        begin
        inc (P[DestPos].Fillness); P[CurrentAimPos].ContDet:=Det;
        end
    end;

  Procedure LoadDetail;
    var
      LoadResult: boolean;
      i, j: byte;
      timeD: longint;
    begin
      If (Charge[1].MinTimeFromPrevious<>0) OR (Charge[NumberOfDetails].Start=0)
        then
        begin
        i:=0;
        Repeat
          inc(i); LoadResult:=DetailMayBeLoaded(i);
          If LoadResult then
            with D[i] do
              begin
              Stage:=1;
              Oper:=Op[i,1];
              Start:=Time; ReglBreach[Cycle-D[i].C]:=0;
              inc(P[Oper.Pos].Fillness); P[Oper.Pos].ContDet:=i;
                {disadvantage - P[Oper.Pos].ValueЁ1}
              j:=0; Repeat inc(j) until Charge[j].Det=i;
              Charge[j].Start:=Start;
              If (i=NumberOfDetails) AND (Charge[1].MinTimeFromPrevious<>0) then
                begin
                inc(Cycle);
                Charge[0].Start:=Start;
                  OFVT[1]:=OFVT[0]; OFVT[0]:=0;
                  For j:=1 to NumberOfDetails do
                    begin
                    D[j].ReglBreach[1]:=D[j].ReglBreach[0];
                    D[j].ReglBreach[0]:=0;
                    end;
                end;
              end;
        Until (i=NumberOfDetails) OR LoadResult;
        end;
    end;

  Procedure UnloadDetail;
    var
      UnloadResult: boolean;
      i, j: byte;
      busyRT: longint;
    begin
      If Section(UnloadPosition, busyRT)=taken then
        begin
        i:=0; UnloadResult:=FALSE;
        Repeat
          inc(i);
          With D[i] do
            If Stage=Op[i, MaxStages+1].Pos then
              if Detail(i, busyRT)>=HadBeenTreatmented then
                begin
                UnloadResult:=TRUE;
                Dec(P[Oper.Pos].Fillness); P[Oper.Pos].ContDet:=0;
                   {Disadvantage - P[Oper.Pos].ValueЁ1}
                inc (Stage); Start:=Time;
                Oper.Pos:=0; Oper.MinDuration:=0; Stage:=0; 
                inc (C);
                j:=0; Repeat inc(j) until Charge[j].Det=i;
                If j=NumberOfDetails then
                  TraceProgram(255, 0, 'k', Time, 0, 0);
                end;
        Until (i=NumberOfDetails) OR UnloadResult;
        end;
    end;

  Procedure CheckRobotsCollision(NR: byte);
    const RobotWidth=1;
    var
      CollisedRobots: array [1..MaxRobots] of byte;
      CRi, D_tmp, i, j, II2: byte;
      timeD: longint;
      Extr_HorCoord, x, x1, x2: real;
    begin                    { Unobjective method }
{exit;}
      If NumberOfRobots=1 then Exit;
   { вычисление положений тестируемого робота до выполнения шага и после }
      II2:=0; CRi:=0; x1:=R[NR].HorCoord-TimeQuantum*RobotHorSpeed*R[NR].HorDir;
      If R[NR].HorCoord*R[NR].HorDir>=P[R[NR].DestP].Coord*R[NR].HorDir
        then x2:=P[R[NR].DestP].Coord else x2:=R[NR].HorCoord;
      If x1>x2 then begin x:=x1; x1:=x2; x2:=x; end;
      For i:=1 to NumberOfRobots do
        if i<>NR then
{ анализ столкновения, запоминание робота и вычисление суммарного индекса важ-
ностей роботов }
          if (R[i].HorCoord>=x1-RobotWidth) AND (R[i].HorCoord<=x2+RobotWidth) then
            begin
            inc(CRi); CollisedRobots[CRi]:=i;
            If R[i].Busy then inc(II2, ord(Detail(CC[i].Det, timeD)));
            end;
      If CRi=0 then Exit;
      If ord(Detail(CC[NR].Det, timeD))<=II2 then
        begin                   { робот NR менее важен }
        Extr_HorCoord:=R[CollisedRobots[1]].HorCoord*R[NR].HorDir;
        For i:=2 to CRi do
          if R[CollisedRobots[i]].HorCoord*R[NR].HorDir<Extr_HorCoord then
            Extr_HorCoord:=R[CollisedRobots[i]].HorCoord*R[NR].HorDir;
        TimeQuantum:=HorTravelTime(R[NR].HorCoord,Extr_HorCoord*R[NR].HorDir,'m');
        R[NR].HorCoord:=Extr_HorCoord*R[NR].HorDir-RobotWidth*R[NR].HorDir;
If Not R[NR].Busy then D_tmp:=0;
TraceProgram(2, NR, 'K', Time-R[NR].SSTime, RobotCoordInPos(NR,x),D_tmp);
R[NR].SSTime:=Time;
        end
                                         else
        For i:=1 to CRi do { робот NR более важен--отводятся остальные роботы }
          begin
          j:=CollisedRobots[i];
          x:=R[j].HorCoord;
          R[j].HorCoord:=
            R[j].HorCoord+TimeQuantum*RobotHorSpeed*R[NR].HorDir;
          If (R[j].HorCoord>=x1-RobotWidth) AND (R[j].HorCoord<=x2+RobotWidth) then
            begin FastWrite('Столкновение роботов',1,1,$4E); {Halt;} end;
If Not R[i].Busy then D_tmp:=0;
TraceProgram(2, i, 'K', Time-R[i].SSTime, RobotCoordInPos(i,x),D_tmp);
R[i].SSTime:=Time;
          end;
    end;
{ Определение столкновения роботов и формирование приказа на перемещение робо-
тов }

  Procedure RobotStep;
    var
      NR: byte;

    Procedure RobotStep_Init (DetC, SourceC, DestC, NR: byte);
      begin
        With R[NR] do
          begin
          Busy:=TRUE;
          With CC[NR] do
            begin
            Det:=DetC;
            SourcePos:=GetPosSect(0, SourceC); DestPos:=DestC;
            CurrentAimPos:=SourceC;
            DestP:=CurrentAimPos;
            If HorCoord<>P[SourceC].Coord then
              begin
              If P[DestP].Coord-HorCoord<0 then HorDir:=-1 else HorDir:=1;
              Element:=1;
              RestTravelTime:=HorTravelTime(HorCoord,P[DestP].Coord,'m')+RobotStopTime[1];
              TraceProgram(2, NR, ' ', Time-SSTime-TimeInc, CC[NR].CurrentAimPos, 0);
newel[nr]^.t0:=time-timequantum;
              SSTime:=-1;
              end
                                          else
              begin
              Element:=2; RestTravelTime:=0; RestStopVertTravelTime:=0;
              end;
            end;
          end;
      end;

    Procedure RobotStep_Hor (NR: byte);
      begin
        With R[NR] do
          if Element IN [1, 5] then
            begin
            HorCoord:=HorCoord+TimeQuantum*RobotHorSpeed*HorDir;
            If HorCoord*HorDir>=P[DestP].Coord*HorDir then
              begin
              CheckRobotsCollision(NR);
              TimeQuantum:=HorTravelTime(HorCoord,P[DestP].Coord,'m');
              inc(Element);
              HorCoord:=P[DestP].Coord; HorDir:=0;
              RestStopVertTravelTime:=RobotStopTime[Element div 2];
              end
                                                      else
              begin
              CheckRobotsCollision(NR);
              TimeQuantum:=0;
              end
            end;
      end;

    Procedure RobotStep_Stop (NR: byte);
      var tmp: DetailStateType;
      begin
        With R[NR] do
          if Element IN [2, 4, 6] then
            begin
            Dec(RestStopVertTravelTime, TimeQuantum);
            If RestStopVertTravelTime<=0 then
              begin
              TimeQuantum:=-RestStopVertTravelTime;
              Case Element of
                2: begin
                   Dec(Time, TimeQuantum); tmp:=Detail(CC[NR].Det, timeD);
                   If SSTime=-1 then
begin
                     SSTime:=Time;
newel[nr]^.t1:=time;
end;
                   Inc(Time, TimeQuantum);
                   If tmp IN [Absent, IsTreatmented] then
                     begin
                     TimeQuantum:=0; RestTravelTime:=MaxLongint;
                     RestStopVertTravelTime:=0;
                     If tmp=IsTreatmented
                       then Element:=1
                       else begin Element:=-1; Busy:=false; end;
                     end
                                                              else
                     begin
                     TakeDetail(CC[NR]);
                     WithLoad:=TRUE; RestStopVertTravelTime:=VertTravelTime;
                     VertDir:=1;
                     RestTravelTime:=
                       RobotStopTime[2]+2*VertTravelTime+
                       HorTravelTime(HorCoord,P[GetPosSect(CC[NR].DestPos,0)].Coord,'m')+
                       RobotStopTime[3];
                     CC[NR].CurrentAimPos:=GetPosSect(CC[NR].DestPos, 0);
                     DestP:=CC[NR].CurrentAimPos;
TraceProgram(2, NR, ' ', Time-SSTime-timequantum, CC[NR].CurrentAimPos, CC[NR].Det);
newel[nr]^.t0:=time-timequantum;
                     SSTime:=-1;
                     end;
                   end;
                4: begin
                   RestStopVertTravelTime:=0;
                   If P[DestP].Coord-HorCoord<0 then HorDir:=-1 else HorDir:=1;
                   end;
                6: begin
                   VertDir:=-1; RestStopVertTravelTime:=VertTravelTime;
                   end;
              end;
              inc(Element);
              end
                                         else
              TimeQuantum:=0;
            end;
      end;

    Procedure RobotStep_Vert (NR: byte);
      var
        Dest_pipe_bend, i: byte;
        CT_pipe_bend: CallTransportType;
      begin
        With R[NR] do
          if Element IN [3, 7] then
            begin
            Dec(RestStopVertTravelTime, TimeQuantum);
            If RestStopVertTravelTime<=0 then
              begin
              TimeQuantum:=-RestStopVertTravelTime; VertDir:=0;
              If Element=3 then
                begin
                VertCoord:=1;
                RestStopVertTravelTime:=RobotStopTime[2];
                end
                           else
                begin
newel[nr]^.t1:=time-timequantum;
                VertCoord:=-1;
                PutDetail(CC[NR]);
                WithLoad:=FALSE; Busy:=FALSE; SSTime:=Time-timequantum;
                i:=0;
                Repeat
                  inc(i); If i=NR then inc(i);
{$B-}           Until (i>NumberOfRobots) OR (DestP IN RobotZones[i]); {$B+}
                If i<=NumberOfRobots then
                  begin
                  dec(SSTime, TimeInc);
                  Element:=0; CallTransport(CT_pipe_bend);
                  With CT_pipe_bend[NR] do
                    begin
                    If PresentFlag
                      then Dest_pipe_bend:=Op[Det, D[Det].Stage+1].Pos
                      else
                        begin FromPos:=DestP-1; Det:=0; Dest_pipe_bend:=0; end;
                    RobotStep_Init (Det, FromPos, Dest_pipe_bend, NR);
                    end;
                  Element:=0;
{if RestStopVertTravelTime<0 then inc (TRSVTT, -RestStopVertTravelTime);}
                  end;
                end;
              Element:=(Element+1) AND 7;
              end
                                         else
              TimeQuantum:=0;
            end;
      end;

    begin
      If TraceKind=TextTrace then delay (DelayTime-DelayTimeMin);
      For NR:=1 to NumberOfRobots do
        with R[NR] do
          if Busy OR CT[NR].PresentFlag then
            begin
            TimeQuantum:=TimeInc;
            With CT[NR] do if PresentFlag then
              RobotStep_Init(Det, D[Det].Oper.Pos, Op[Det, D[Det].Stage+1].Pos, NR);
            dec(RestTravelTime, TimeQuantum);
            Repeat
              Case Element of
                1,5:   RobotStep_Hor (NR);
                2,4,6: RobotStep_Stop(NR);
                3,7:   RobotStep_Vert(NR);
              end;
            Until (TimeQuantum<=0) OR (Element=0);
            end;
    end;

  Procedure Control;
    var
      flag: boolean;
      i: integer;
    begin
      Repeat
        inc(CalcTimeParm[3]);
        If KeyPressed then KeyControl;
        CallTransport(CT);
        DetectAutoTime (Time);
        LoadDetail; UnloadDetail; RobotStep; Trace(FALSE);
        i:=0;
        Repeat
          inc (i); flag:=Detail(i, timeD)=Completed
        until Not flag OR (i=NumberOfDetails);
      until flag;
      Terminate(#0);
    end;

begin end.

