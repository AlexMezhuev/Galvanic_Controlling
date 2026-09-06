Unit GCState;
  interface
  Uses TPCRT, GCInter, GCTime;
  Function Section (N: byte; var busyRT: longint): SectionStateType;
  Function GetRobot (Pos, Det: byte): byte;
  Function RobotCoordInPos(NR: byte; var delta: real): byte;
  Function GetPosSect (Sect, Pos: byte): byte;
  Function HorTravelTime (U1, U2: real; Value: char): integer;
  Function DetailMayBeLoaded (Det: byte): boolean;
  Function II (Det: byte; CalcTime: longint): real;
  Function TravelToNextSectIsPossible (Det: byte): boolean;
  Function Detail (N: byte; var timeD: longint): DetailStateType;
  Function Collision (Det1: byte; var Det2: byte): boolean;
  Function CallTransport (var CT: CallTransportType): boolean;
  Procedure DetectAutoTime (var Time: longint);

  implementation
  Function Section (N: byte; var busyRT: longint): SectionStateType;
     var
       i, j: integer;
       tmp: longint;
     begin
if P[N].Value=0 then halt;
       busyRT:=0;
       If P[N].Fillness=P[N].Value then
         begin
           busyRT:=MaxLongint; Section:=taken;
           j:=1;
           While j<=P[N].Value do
             begin
               i:=P[N+j-1].ContDet;
               tmp:=D[i].Oper.MinDuration-(Time-D[i].Start);
               If tmp<busyRT then busyRT:=tmp;
               inc (j);
             end;
         end
    	                  else
       Section:=free;
    end;
{ Функция возвращает free, если позиция занята не полностью, и taken, если по-
лностью; busyRT cодержит время, в течение кот. позиция еще будет занята }

  Function GetRobot (Pos, Det: byte): byte;
    var j, NR: byte;
    begin
      If Pos=0 then Pos:=D[Det].Oper.Pos;
      If Pos=0 then GetRobot:=0 else
        begin
          NR:=1; While Not (Pos IN RobotZones[NR]) do inc(NR);
          GetRobot:=NR;
        end;
    end;
{ Функция определяет номер робота, обслуживающего заданную позицию или деталь;
в первом  случае ф. вызывается как  GetRobot (Pos, 0),  во втором как GetRobot
(0, Det) }

  Function RobotCoordInPos(NR: byte; var delta: real): byte;
  var i, Pos: byte;
  begin
    With R[NR] do
      begin
      If HorCoord>=P[NumberOfPositions].Coord then Pos:=NumberOfPositions
                             else
      begin
      i:=NumberOfPositions; While HorCoord<P[i].Coord do dec(i);
      If HorCoord-P[i].Coord<P[i+1].Coord-HorCoord
        then Pos:=i else Pos:=i+1;
      end;
      delta:=HorCoord-P[Pos].Coord; RobotCoordInPos:=Pos;
      end;
  end;
{ Функция определяет номер ванны, к которой ближе всего расположен робот; в пе-
ременную delta выводится расстояние от робота до этой ванны }
 
  Function GetPosSect (Sect, Pos: byte): byte;
    var t: byte;
    begin
      If Sect=0 then
        begin t:=Pos; While P[t].Value=0 do dec (t); end
               else
        if Section(Sect, busyRT)=free then
          begin t:=Sect; While P[t].ContDet<>0 do inc(t); end
                                      else
          t:=0;
      GetPosSect:=t;
    end;
{ По номеру участка  (вызов GetPosSect (Sect, 0)) возвращает номер первой сво-
бодной позиции на участке, выполняющей ту же операцию;  если все ванны заняты,
возвращает 0. По номеру ванны (вызов GetPosSect (0, Pos)) возвращает номер пе-
рвой ванны на позиции, выполняющей ту же операцию. }

  Function HorTravelTime (U1, U2: real; Value: char): integer;
    begin
      If UpCase(Value)='M'
        then HorTravelTime:=Round(Abs(U1-U2)/RobotHorSpeed)
        else HorTravelTime:=Round(Abs(P[Round(U1)].Coord-P[Round(U2)].Coord)/RobotHorSpeed);
    end;
{ Время перемещения робота от ванны B1 к ванне B2 }

  Function DetailMayBeLoaded (Det: byte): boolean;
    var
      i, j: byte;
      busyRT, timeD: longint;
    begin
{$B-} If (Cycle=1) AND (Detail(Charge[1].Det, timeD)=NotTreatmented) then
        DetailMayBeLoaded:=TRUE
                                                                     else
        begin
        DetailMayBeLoaded:=FALSE;
        If (D[Det].C=Cycle) AND (Detail(Det, timeD)=NotTreatmented) AND
           (Section(Op[Det, 1].Pos, busyRT)=free) then
{$B+}     begin
          j:=1; While Charge[j].Det<>Det do inc(j);
          For i:=1 to j-1 do
            if Detail(Charge[i].Det, timeD)=NotTreatmented then Exit;
          If Charge[j].MinTimeFromPrevious<=Time-Charge[j-1].Start then
            DetailMayBeLoaded:=TRUE;
          end;
        end;
    end;
{ Функция определяет возможность загрузки детали Det на обрабатывающую линию }

  Function II (Det: byte; CalcTime: longint): real;
    var
      tmp: DetailStateType;
      timeD: longint;
    begin
      tmp:=Detail(Det, timeD);
      If CalcTime=MaxLongint then CalcTime:=timeD;
      Case tmp of
        Completed, Carried: II:=-MaxLongint;
        NotTreatmented: if DetailMayBeLoaded(Det) then II:=0 else II:=-MaxLongint;
        else
          with D[Det].Oper do II:=(CalcTime-MinDuration)/(MaxDuration-MinDuration);
      end;
    end;
{ Индекс важности первоочередной обработки детали Det }

  Function TravelToNextSectIsPossible (Det: byte): boolean;
    var
      Col_D_D2: boolean;
      Det2, Det3: byte;
      timeD: longint;
      DetailState: DetailStateType;
    begin
      TravelToNextSectIsPossible:=FALSE;
      DetailState:=Detail(Det, timeD);
      If (D[Det].Stage<Op[Det,MaxStages+1].Pos) AND
        ((DetailState>NotTreatmented) OR DetailMayBeLoaded(Det)) then
        If Section(Op[Det, D[Det].Stage+1].Pos, busyRT)=free then
          begin
          Col_D_D2:=Collision(Det, Det2);
          If Not Col_D_D2 then TravelToNextSectIsPossible:=TRUE else
            if {Collision(Det2, Det3) AND (Det3=Det) AND}
               (SupportOp[D[Det].Oper.Number].PRTY>SupportOp[D[Det2].Oper.Number].PRTY)
                  then TravelToNextSectIsPossible:=TRUE;
          end;
    end;

  Function DontTravelAway (NR, Det: byte): boolean;
    var             
      DCur, i, LB, RB: byte;
      ConstPartOfTravelTime, timeD, timeDi: longint;
      IICur, IItmp, MaxII, MaxIICur: real;
      tmp: DetailStateType;
    Procedure MinMax3(N1,N2,N3: byte; var Min,Max: byte);
      var
        i: byte;
        a: array [1..3] of byte;
      begin
        a[1]:=N1;a[2]:=N2;a[3]:=N3; Min:=N1;Max:=N2;
        For i:=2 to 3 do
          if a[i]>Max then Max:=a[i] else if a[i]<Min then Min:=a[i];
      end;
    begin
      DontTravelAway:=FALSE;
exit;
      For i:=1 to NumberOfDetails do
        if Detail(i, timeD)=Critical then
          if (GetRobot(0,i)=NR) AND TravelToNextSectIsPossible(i) then exit;
      If ord(Detail(Det, timeD)) IN [2, 3, 4] then
        With D[Det] do
          if (Oper.MinDuration<=30) AND TravelToNextSectIsPossible(Det) then
            begin
            ConstPartOfTravelTime:=2*VertTravelTime+HorTravelTime(Oper.Pos,
            Op[Det, Stage+1].Pos,'p')+Oper.MinDuration-timeD;
            MaxII:=-1; MaxIICur:=-1;
            For i:=1 to 3 do inc (ConstPartOfTravelTime, RobotStopTime[i]);
            For i:=1 to NumberOfDetails do
              begin
              tmp:=Detail(i, timeDi);
              If (GetRobot(0, i)=GetRobot(0, Det)) AND (ord(tmp) IN [2,3,4]) then
                if TravelToNextSectIsPossible(i) then
                  begin { что будет с другими деталями, если стоять на месте }
                  IICur:=II(i, timeDi);
                  If IICur>MaxIICur then begin DCur:=i; MaxIICur:=IICur; end;
                  IItmp:=II(i, timeDi+ConstPartOfTravelTime+
                    HorTravelTime(Op[Det, Stage+1].Pos, D[i].Oper.Pos,'p'));
                  If IItmp>MaxII then MaxII:=IItmp;
                  end;
              end;
            If MaxIICur=-1 then IItmp:=MaxII+1
                           else
              begin   { что будет с дет. Det, если обслужить какую-л. дет. }
              MinMax3(Oper.Pos, D[DCur].Oper.Pos, GetPosSect(Op[DCur,
                      D[DCur].Stage+1].Pos,0), LB, RB);
              timeD:=timeD+2*VertTravelTime+RobotStopTime[1]+
                     2*HorTravelTime(LB, RB, 'p');
              For i:=1 to 3 do inc (timeD, RobotStopTime[i]);
              IItmp:=II(Det, timeD);
              end;
            If IItmp>MaxII then DontTravelAway:=TRUE;
            end;
    end;
{ Функция  определяет,  может ли робот отойти  от позиции.  Решение зависит от
продолжительности операции }

  Function Detail (N: byte; var timeD: longint): DetailStateType;
    var
      i: integer;
      tmp: DetailStateType;
    begin
      timeD:=0;
      If N=0 then tmp:=Absent
             else
        begin
        tmp:=Pred(Carried);
        For i:=1 to NumberOfRobots do
          with R[i] do if (CC[i].Det=N) AND (Element>=3) then
            tmp:=Carried;
        If tmp<>Carried then
          if D[N].Stage=0 then
            if D[N].C=Cycle then tmp:=NotTreatmented else tmp:=Completed
      		           else
	  if D[N].Stage=Op[N, MaxStages+1].Pos+1 then tmp:=Completed
	                   else
            begin
              timeD:=Time-D[N].Start;
              If timeD<D[N].Oper.MinDuration then
                tmp:=IsTreatmented
                                           else
                if timeD<=D[N].Oper.MaxDuration then
                  tmp:=HadBeenTreatmented
                                                 else
                  tmp:=Critical;
            end;
        end;
      Detail:=tmp;
  end;
{ Функция определяет состояние детали  ( 0) не обраб., 1) обраб., 2) обрабо-
тана и находится в ванне, 3) критич. состояние (превышение макс. времени на-
хождения в ванне),  4) обраб. и перенесена за пределы линии);  для состояний
1-3 в переменную timeD выводится время, прошедшее с начала обработки }

  Function Collision (Det1: byte; var Det2: byte): boolean;
    var i: byte;
    begin
      Collision:=FALSE;
      If Op[Det1, MaxStages+1].Pos-D[Det1].Stage>1 then
        begin
          i:=0; Det2:=0;
          Repeat
            inc(i);
            if i<>Det1 then
              if D[i].Stage<Op[i, MaxStages+1].Pos then
                if ((Op[Det1, D[Det1].Stage+1].Pos=Op[i, D[i].Stage+1].Pos)
                  AND (Op[i, D[i].Stage].Pos=Op[Det1, D[Det1].Stage+2].Pos))
                    then Det2:=i;
          until (i=NumberOfDetails) OR (Det2=i);
          If Det2=i then Collision:=TRUE;
        end;
    end;
{ Функция определяет,  возможна ли пространственная взаимоколлизия детали Det1
при перемещении ее на следующую позицию с какой-л. деталью; если коллизия воз-
можна, возвращается номер соколлизирующей детали }

  Function CallTransport (var CT: CallTransportType): boolean;
    var
      DTA, tmp1: boolean;
      Det2, i, NR: byte;
      tmp: DetailStateType;
      timeD: longint;
      IIi, MaxII: real;
    begin
      tmp1:=FALSE;
      For NR:=1 to NumberOfRobots do
        begin
        MaxII:=-MaxLongint; DTA:=FALSE;
        if {Not R[NR].Busy} (r[nr].element in [0,2]) and (r[nr].reststopverttraveltime<=0) then
{ robot will rush about }
          begin
          i:=0;
          Repeat
            inc(i); tmp:=Detail(i, timeD);
            If Not (tmp IN [NotTreatmented, Completed, Carried]) then
              if GetRobot(0, i)=NR then
              with D[i].Oper do
                begin
                IIi:=II(i, timeD);
                DTA:=DontTravelAway(NR, i);
                If ((IIi>MaxII) OR DTA) AND TravelToNextSectIsPossible(i) then
                  with CT[NR] do
                    begin
                    MaxII:=IIi;
                    FromPos:=Pos;
                    TimeUntilCall:=MinDuration-timeD;
                    Det:=i;
                    end;
                end;
          until (i=NumberOfDetails) OR DTA;
          end;
        CT[NR].PresentFlag:=MaxII>=0; CT[NR].FutureFlag:=(MaxII<0)AND(MaxII>-MaxLongint);
        CT[NR].PresentFlag:=CT[NR].PresentFlag OR CT[NR].FutureFlag;
        tmp1:=tmp1 OR CT[NR].PresentFlag OR DTA;
        end;
      CallTransport:=tmp1;
  end;
{ Функция определяет, требуется ли перемещение транспорта к ваннам }

  Procedure DetectAutoTime (var Time: longint);
    var
      Det, NR: byte;
      RT, timeD: longint;
    begin
      If AutoTimeRegime then
        begin
        TimeInc:=MaxLongint;
        For NR:=1 to NumberOfRobots do
          with R[NR] do
            if Busy then
              if (RestTravelTime=MaxLongint)AND(cc[nr].Det<>0) then begin Detail(cc[nr].det,timed);
RT:=D[cc[nr].Det].Oper.MinDuration-timeD;
If RT<TimeInc then TimeInc:=RT;
end else
              if RestTravelTime<TimeInc then TimeInc:=RestTravelTime
                                        else begin end
                    else
          with CT[NR] do
            if PresentFlag then TimeInc:=0
                           else
{never}       if FutureFlag then if TimeUntilCall<TimeInc then TimeInc:=TimeUntilCall;
        For Det:=1 to NumberOfDetails do
          if Detail(Det, timeD)=IsTreatmented then
            begin
            RT:=D[Det].Oper.MinDuration-timeD;
            If RT<TimeInc then TimeInc:=RT;
            end;
        If Charge[NumberOfDetails].Start=0 then
          begin
          Det:=0;
          Repeat
            inc(Det);
          until (Detail(Charge[Det].Det, timeD)=NotTreatmented) OR (Det=NumberOfDetails);
          If Det<>1 then
            begin
            RT:=Charge[Det].MinTimeFromPrevious-(Time-Charge[Det-1].Start);
            If  RT<TimeInc then TimeInc:=RT
            end
                    else
            TimeInc:=0;
          end;
        TimeScale:=TimeInc/DelayTime*1000; PutTimeScale (TimeScale);
        end
                        else
        TimeInc:=1;
      inc(Time, TimeInc);
    end;

begin end.
