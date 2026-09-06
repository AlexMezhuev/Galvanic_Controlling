(* Разработка алгоритмов управления транспортной системой РТК галь- *)
(* ванопокрытий с использованием  методов ситуационного управления. *)
(* Графическое иллюстрирование работы РТК                           *)
(* Ляшков А., Васильев С.А., Межуев А.                              *)

{$X+,R+}
Unit GCTrace;
interface
  uses TPCrt, TPString, Graph, GCInter, GCState;
  Procedure Trace(imp: boolean);
  Procedure InitScreen(Animation: boolean);
  Procedure TraceTerminate;

type
  RobotImageType=record
    Xr: longint;                          { текущая Х-координата робота в мм }
    X: word;                          { текущая Х-координата робота в точках }
    Y: byte;                          { текущая У-координата робота в точках }
{   Tk: longint;                    время конца выполнения команды в 0.1 сек }
    Yi: byte;               { количество 0.1 сек движений вверх-вниз, не от- }
                            { ражённых ещё на экране  из-за малого  масштаба }
    ReflectedEl: byte;                         { отображаемый элемент работы }
    Corrected: boolean;  { производилась ли коррекция после гор. перемещения }
  end;
  PositionImageType=record
    Yt: byte;                                       { текущая высота столбца }
    U1: boolean;                                 { есть ли столбик индикации }
    NumberOfOp: byte;
  end;
var
  RobotImage: array [1..MaxRobots] of RobotImageType;
  PositionImage: array [1..MaxRS] of PositionImageType;

implementation
const
  YY = 300;
var
  GraphicDriver, GraphicMode: integer;
  T: real;
  D_tmp, NR, P_tmp: byte;
  Temp: byte;                          { масштаб скорости движения по экрану }
  RR, RR1: word;
  St: string;
  YP: word;                                 { высота подъёма детали в точках }
  Smoothness: real;                      { коэффициент плавности перемещения }

                             { not used }
  CycleTime: longint;                               { total cycle time, dsec }
  LowerLiftTime: longint;                     { lowering and lift time, dsec }
  StopAfterLifting: longint;                { pause time after lifting, dsec }
  StopAfterPreMoving: longint;{ pause time after moving of empty robot, dsec }
  StopAfterMovingWithDetail: longint; { pause time after moving with detail, dsce}

procedure DrawDiagram(P_tmp: byte);            { чертит  столбик-диаграмму и }
  var i, X_Pos: word;                                 { выводит  название  операции }
  begin
  NR:=GetRobot(P_tmp, 0); D_tmp:=P[P_tmp].ContDet;
  X_Pos:=RR*(P_tmp-1)+RR1 div 2;
{--------------------------- столбик-диаграмма ------------------------------}
  With PositionImage[P_tmp], P[P_tmp], RobotImage[NR] do
    begin
    Yt:=0;
    SetColor(15);
    Rectangle(X_Pos-6,YY+50,X_Pos+6,YY+150);
    SetColor(14);
    With D[D_tmp].Oper do i:=YY+150-Round(MinDuration*100/MaxDuration);
    Line(X_Pos-6,i,X_Pos+6,i);
    U1:=true;
{------ название операции для позиций, поддерживающих более 1 операции ------}
    If NumberOfOp>1 then
      begin         
      SetFillStyle(1,0); Bar(X_Pos-8, 10, X_Pos, YY-45-YP);
      SetTextStyle(0, VertDir, 1); SetColor(15);
      OutTextXY(X_Pos, 10, SupportOp[D[D_tmp].Oper.Number].Name);
      SetTextStyle(0, HorizDir, 1);
      end;
    end;
  end;

procedure Pokaz(NR: byte);                { показывает робот в текущем месте }
  begin
  With RobotImage[NR] do
    begin
    SetFillStyle(1,12);
    Bar(X-5,YY-34-YP,X+5,YY-23-YP);
    Bar(X-1,YY-23-YP,X+1,YY-6+Y-YP);
    Bar(X-2,YY-2-YP+Y,X+2,YY-5+Y-YP);
    If R[NR].WithLoad then
      begin
      SetFillStyle(1,14);
      Bar(X-3,YY-1-YP+Y,X+3,YY+Y+14-YP)
      end
    end;
 end;

procedure DvigLev(NR: byte);  { смещение изображения робота на 1 точку влево }
  begin
  With RobotImage[NR] do
    begin
    SetFillStyle(1,0);
    Bar(X+5,YY-34-YP,X+7,YY-31-YP);
    Bar(X+5,YY-26-YP,X+7,YY-23-YP);
    Bar(X+1,YY-22-YP,X+4,YY-6+Y-YP);
    Bar(X+2,YY-2-YP+Y,X+5,YY-5+Y-YP);
    If R[NR].WithLoad then Bar(X+3,YY-1-YP+Y,X+6,YY+14+Y-YP);
    SetFillStyle(1,7);
    Bar(X+5,YY-27-YP,X+8,YY-30-YP);
    X:=X-1;
    Pokaz(NR)
    end;
  end;

procedure DvigPr(NR: byte);  { смещение изображения робота на 1 точку вправо }
  begin
  With RobotImage[NR] do
    begin
    SetFillStyle(1,0);
    Bar(X-5,YY-34-YP,X-7,YY-31-YP);
    Bar(X-5,YY-26-YP,X-7,YY-23-YP);
    Bar(X-1,YY-22-YP,X-4,YY-6+Y-YP);
    Bar(X-2,YY-2-YP+Y,X-5,YY-5+Y-YP);
    If R[NR].WithLoad then Bar(X-3,YY-1-YP+Y,X-6,YY+14+Y-YP);
    SetFillStyle(1,7);
    Bar(X-5,YY-27-YP,X-8,YY-30-YP);
    X:=X+1;
    Pokaz(NR)
    end;
  end;

procedure Move(NR: byte; newXr: longint);{ передвижение робота на другое место }
  var
    S: real;
    i, s1: word;
  begin
  With RobotImage[NR] do
    begin
    Xr:=newXr;
    S:=R[NR].HorCoord/P[NumberOfPositions].Coord;
    s1:=Round(S*(640-RR-RR1)+RR1 div 2);
    If X<s1 then for i:=X to s1-1 do DvigPr(NR);
    If X>s1 then for i:=s1 to X-1 do DvigLev(NR);
    X:=s1;
    end;
  end;

procedure Init(NR: byte; newXr: longint; newY: byte);
  var S: real;                                  { начальная установка робота }
  begin
  With RobotImage[NR] do
    begin
    Xr:=newXr;
    Y:=newY;
    S:=R[NR].HorCoord/P[NumberOfPositions].Coord;
    X:=Round(S*(640-RR-RR1)+RR1 div 2);
    Yi:=0;
    ReflectedEl:=0;
    Corrected:=FALSE;
    Pokaz(NR);
    end;
  end;
(*
function VipoLn(NR: byte);                            { выполнена ли команда }
  begin
???With RobotImage[NR] do
     if Tk=0 then VipoLn:=Time*10=0 else VipoLn:=Time*10>=Tk
  end;
*)
procedure Vniz(NR: byte);            { перемещение робота на одну точку вниз }
  begin
  With RobotImage[NR] do
    begin
    inc(Yi);
    If Yi<>5 then Exit else Yi:=0;
    SetColor(0);
    Line(X-3,YY-6-YP+Y,X+3,YY-6-YP+Y);
    Line(X-3,YY-1-YP+Y,X+3,YY+Y-1-YP);
    SetColor(12);
    Line(X-1,YY-6-YP+Y,X+1,YY-6-YP+Y);
    Line(X-2,YY-1-YP+Y,X+2,YY-1-YP+Y);
    SetColor(14);
    Line(X-3,YY-YP+15+Y,X+3,YY-YP+15+Y);
    Y:=Y+1;
    end;
  end;

procedure Otp(NR: byte);                                 { отпускание детали }
  var i: word;
  begin
  With RobotImage[NR] do
    begin
    While Y<>YP do
      begin Yi:=4; Vniz(NR); delay(Round((DelayTime-DelayTimeMin)*Smoothness)); end;
    ReflectedEl:=0;
    DrawDiagram(D[CC[NR].Det].Oper.Pos);
    end;
  end;

procedure Vverh(NR: byte);          { перемещение робота на одну точку вверх }
  var i: byte;
  begin
  With RobotImage[NR] do
    begin
    inc(Yi);
    If Yi<>5 then Exit else Yi:=0;
    SetColor(12);
    Line(X-2,YY-6-YP+Y,X+2,YY-6-YP+Y);
    SetColor(14);
    Line(X-3,YY-1-YP+Y,X+3,YY-1-YP+Y);
    If YP-Y>=10 then SetColor(0)
                else SetColor(P[D[CC[NR].Det].Oper.Pos].Colour);
    Line(X-3,YY-YP+14+Y,X+3,YY-YP+14+Y);
    Y:=Y-1;
    end;
  end;

procedure Zahv(NR: byte);                                    { захват детали }
  begin
  With RobotImage[NR] do
    begin
    While Y<>0 do
      begin Yi:=4; Vverh(NR); delay(Round((DelayTime-DelayTimeMin)*Smoothness)); end;
    ReflectedEl:=4;
    SetFillStyle(1,0);
    D_tmp:=CC[NR].Det;
    With PositionImage[D[D_tmp].Oper.Pos] do
      begin
        U1:=false;
        If Detail(D_tmp,timeD)=Critical then
           begin
             Bar(X-15,0,X+15,10);
             Str(timeD:1,St);
             SetColor(14);
             OutTextXY(X-15,0,'+'+St);
           end;
        { недообработка не предполагается }
      end;
    Bar(X-6,YY+3*RR1 div 2,X+6,YY+150);
    end;
  end;


procedure Korr(NR: byte);           { корректировка  текущей Х-координаты -- }
  begin                             { робот выставляется строго над позицией }
    Move(NR, Round(P[R[NR].DestP].Coord*1000));
    RobotImage[NR].Corrected:=TRUE;
  end;

procedure Deistvie(NR: byte);        { выполнение текущей команды за 0.1 сек }
  begin
  With RobotImage[NR], R[NR] do
    begin
    Case ReflectedEl of
      2,6:
         If Not RobotImage[NR].Corrected then Korr(NR);
      7: begin                          { опускание на 1 точку вниз с грузом }
           Vniz(NR);
           If Element=0 then Otp(NR);
         end;
      3: begin                           { поднятие на 1 точку вниз с грузом }
           Vverh(NR);
           If Element=4 then Zahv(NR);
         end;
      1,5:
         begin
         If HorDir=1 then Move(NR, Round(Xr+RobotHorSpeed*100))   { вправо }
                     else Move(NR, Round(Xr-RobotHorSpeed*100));  { влево  }
         robotimage[nr].corrected:=FALSE;
         end;
    end;
    end;
  end;

procedure InitScreen;
  var
    i, j: byte;
    X: word;
    PrevOpName: string;
  begin
{-----------Необходимые условия использования графической трассировки--------}
  Animation:=TRUE;
  If AutoTimeRegime then
    begin AutoTimeRegime:=FALSE; TimeScale:=1; DelayTime:=40; end;
{--------------------------вычисление констант-------------------------------}
  LowerLiftTime:=10*VertTravelTime;
  YP:=LowerLiftTime div 5;
  RR:=640 div NumberOfPositions;
  RR1:=(RR div 3)*2;
  Smoothness:=0.1;
{ Write ('Темп ускорения времени: '); ReadLn(Temp); Temp:=10; }
{----------------------- инициализация инфо о ваннах ------------------------}
  For i:=1 to NumberOfPositions do with PositionImage[i] do
    begin
    Yt:=0;
    U1:=FALSE;
    end;
{----------------------- инициализация графики ------------------------------}
  GraphicDriver := Detect;
  InitGraph(GraphicDriver, GraphicMode, '');
{ case when "egavga.bgi" is not found }
{ ---------------- изображение ванн и названий операций ---------------------}
  X:=0;
  For i:=1 to NumberOfPositions do
    begin
    Bar(X,YY,X+1,YY+RR1);
    Bar(X,YY+RR1,X+RR1,YY+RR1+1);
    Bar(X+RR1-1,YY,X+RR1,YY+RR1);
    SetTextStyle(0, VertDir, 1);
    SetColor(15);
    j:=1;
{$B-}While (j<=NumberOfSupportOp) AND (SupportOp[j].Pos<>i) do inc(j);{$B+}
    If j<=NumberOfSupportOp then PrevOpName:=SupportOp[j].Name;
    OutTextXY(X+RR1 div 2,10,PrevOpName);
    SetColor(5);
    SetTextStyle(0, HorizDir, 1);
    Str(i,St);
    OutTextXY(X,YY-70,St);
    X:=X+RR
    end;
{ ---------------- изображение подвески автооператоров ----------------------}
  SetFillStyle(1,7);
  Bar(0,YY-27-YP,640,YY-30-YP);
{    ---------------- изображение содержимого ванн --------------------------}
  X:=0;
  For i:=1 to NumberOfPositions do
    begin
    SetFillStyle(1, P[i].Colour);
    Bar(X+2,YY+5,X+RR1-2,YY+RR1-1);
    If P[i].ContDet<>0 then
      begin
      SetFillStyle(1,14);
      Bar(X+(RR1 div 2-3),YY,X+(RR1 div 2)+3,YY+14)
      end;
    X:=X+RR;
    end;
{ ----------- вывод инфо о текущем и полном временах процесса ---------------}
  SetColor(2);
  OutTextXY(10,457,'С НАЧАЛА ЦИКЛА ПРОШЛО       СЕКУНД');
{ Str(Round(CycleTime/10):4,St);
  OutTextXY(350,457,'Время полного цикла '+St+' секунд.');}
{        ---------------- изображение роботов -------------------------------}
  For NR:=1 to NumberOfRobots do       { ставим робота над исходной позицией }
    Init(NR, Round(R[NR].HorCoord)*1000, YP);{  в опущенном положении        }
  end;

procedure LoadDetail;     { работа робокара, обслуживающего позицию загрузки }
 var X: word;
 begin
 If (P[LoadPosition].ContDet<>0) AND Not PositionImage[LoadPosition].U1 then
   begin
   DrawDiagram(LoadPosition);
   X:=RR*(LoadPosition-1)+RR1 div 2;
   SetFillStyle(1,14); Bar(X-3, YY-1, X+3, YY+RR1-2);
   PositionImage[LoadPosition].U1:=TRUE;
   end;
 end;

procedure UnLoadDetail;   { работа робокара, обслуживающего позицию выгрузки }
  var X: word;
  begin
  If (P[UnLoadPosition].ContDet=0) AND PositionImage[UnLoadPosition].U1 then
    begin
    X:=RR*(UnLoadPosition-1)+RR1 div 2;
    SetFillStyle(1,0); Bar(X-3, YY-1, X+3, YY+4); Bar(X-6,YY+30,X+6,YY+150);
    SetFillStyle(1,P[UnLoadPosition].Colour); Bar(X-3, YY-YP+31, X+3, YY+14);
    PositionImage[UnLoadPosition].U1:=FALSE;
    end;
  end;

procedure Trace(imp: boolean);
  const Ending: string[10]=' АЫЫЫ     ';
  var
    i: byte;
    X: word;                { абсцисса столбика индикации         }
    Ytn: longint;           { размер столбика индикации           }
    busyRT: longint;
  begin
  LoadDetail; UnloadDetail;
  
  T:=0;
  While T<=TimeInc do
    begin
{     If RobotImage[NR].ReflectedEl<>R[NR].Element      }
      For NR:=1 to NumberOfRobots do Deistvie(NR);
      T:=T+Smoothness;
      Delay(Round((DelayTime-DelayTimeMin)*Smoothness));
    end;
  For NR:=1 to NumberOfRobots do RobotImage[NR].ReflectedEl:=R[NR].Element;
{ ----------------------------- вывод времени -------------------------------}
  SetFillStyle(1,0);
  Bar(187,457,220,465);
  SetColor(2);
  Str(Time:1, St); OutTextXY(187,457,St);
  Bar(283,457,291,465); OutTextXY(283,457,Ending[ord(St[Length(St)])-47]);
{----------------- столбики продолжительностей процессов --------------------}
  For i:=1 to NumberOfPositions do
    with PositionImage[i] do if U1 then
      begin
        Section(i, busyRT);
        D_tmp:=P[i].ContDet;
        If D_tmp<>0 then{деталь может быть вынута в GCCtrl, GCTrace отстает от нее}
          begin
          Ytn:=Round((D[D_tmp].Oper.MinDuration-busyRT)*100/D[D_tmp].Oper.MaxDuration);
          If Ytn<>Yt then
            begin
              If Yt<100 then SetFillStyle(1,9)
                        else begin {Write(#7);} SetFillStyle(1,4) end;
              X:=(i-1)*RR+RR1 div 2;
              If Ytn<=149-1.5*RR1 then Bar(X-5,YY+149-Ytn,X+5,YY+149-Yt);
              Yt:=Ytn;
            end
          end;
      end
  end;

  Procedure TraceTerminate;
    begin
      CloseGraph;
      RestoreWindow(1,1,80,25,TRUE,StartScreen);
      TextAttr:=StartColor;
    end;

begin
  TraceKind:=GraphicTrace;
end.
