Unit GCTrace;
  interface
  Uses TPCRT, TPString, GCInter, GCState;
  Procedure InitScreen(Animation: boolean);
  Procedure Trace(imp: boolean);
  Procedure TraceWhenNotAnimation;
  Procedure TraceTerminate;

  implementation

  Procedure InitScreen(Animation: boolean);
    begin
      If Animation then
        begin
        TextBackGround (Black); ClrScr;
        FastWrite ('Оптимизируемая функция: ', 9, 1, LightGray);
        FastWrite ('    Файл                  Анимация                   Время             Опции    ',
                   1, 1, $70);
        Window (64, 2, 80, 25); TextAttr:=$1F; ClrScr;
        GoToXY(1, 2); Write('Цикл:',CRLF,'Время:',CRLF,'Масштаб:');
        Window(1, 19, 80, 25); TextBackGround (Green); ClrScr;
        end
                   else
        begin
        Window(1,1,80,25); TextAttr:=7; ClrScr;
        Write ('Время:', CRLF, 'Масштаб:', CRLF, 'Оптимизируемая функция: ');
        end;
    end;

  Procedure TraceWhenNotAnimation;
    begin
      GoToXY (8, 1); Write (Time:1);
      GoToXY (10,2); Write (TimeScale:1:1); ClrEol;
      GoToXY (25,3); Write (OFVT[0]:1); ClrEol;
    end;

  Procedure TraceTerminate;
    begin
      RestoreWindow(1,1,80,25,TRUE,StartScreen);
      TextAttr:=StartColor;
    end;

  Procedure Trace(imp: boolean);
    Var NRB: byte;
    i, j, tmp: integer;
    WC: WindowCoordinates;

    Procedure TraceSections;
      var i: integer;
      begin
        Window(1, SA[State].Y+1, 10, 25);
        Write ('Номер', CRLF, 'Дет(Вм.)', CRLF, 'Cост.', CRLF, 'Ост. вр.');
        i:=P0-1; tmp:=3;
        Repeat
          Repeat inc (i) until P[i].Value<>0; tmp:=tmp+8;
          Window(tmp, SA[State].Y+1, tmp+8, 25);
          WriteLn (i:4, CRLF, P[i].Fillness:3, '(', P[i].Value, ') ');
          If Section(i,busyRT)=free then WriteLn(' своб.') else WriteLn(' занят');
          Write (busyRT:5);
        until (tmp>59) OR (i=NumberOfPositions);
        If i=NumberOfPositions then
          begin Window(8+tmp, SA[State].Y+1, 80, 25); ClrScr; end;
      end;

    Procedure TraceDetails;
      var i: integer;
      begin
        Window(1, SA[State].Y+1, 9, 25);
        Write ('Номер', CRLF, 'Сост.', CRLF, 'Позиция',
                CRLF, 'Время', CRLF, 'Регл.', CRLF, 'Наруш.');
        For i:=1 to NumberOfDetails do
        begin
          Window(1+i*10, SA[State].Y+1, (i+1)*10, 25);
          WriteLn (i:5);
          tmp:=ord(Detail(i, timeD));
          Case  tmp of
            1: Write ('  Не обр.', ' ':30);
            2: Write (' Обрабат.');
            3: Write (' Обработ.');
            4: FastWriteWindow(' Критич. ', WhereY, WhereX, $24);
            5: Write (' Заверш. ', ' ':30);
            6: Write (' Перенос. ',  Op[i, D[i].Stage].Pos:4, '->',
               Op[i, D[i].Stage+1].Pos:1, ' ':21);
          end;
          WriteLn;
          If tmp in [2, 3, 4] then
            WriteLn (D[i].Oper.Pos:5,' ':3, CRLF, timeD:6, CRLF,
                     D[i].Oper.MinDuration:6);
          If D[i].C=Cycle-1 then tmp:=1 else tmp:=0;
          Write (D[i].ReglBreach[tmp{0}]:5);
          ClrEol;
        end;
      end;

    Procedure TraceRobots;
      var i: integer;
      begin
        Window(1, SA[State].Y+1, 11, 25);
        Write ('Номер', CRLF, 'Кооpд.', CRLF, 'Назнач.',
                CRLF, 'Тpавеpса', CRLF, 'Нагрузка');
        For i:=1 to NumberOfRobots do
          with R[i] do
            begin
            Window(3+i*9, SA[State].Y+1, 3+(i+1)*9, 25);
            WriteLn (i:5, CRLF, RobotCoordInPos(i,delta):5);
            If HorDir=0 then WriteLn ('-':5) else WriteLn (DestP:5);
            If VertCoord=-1 then WriteLn (' опущена') else WriteLn(' поднята');
            If WithLoad then Write ('  есть') else Write ('   нет');
            end;
      end;

    begin
      if imp then dec(T0);
      StoreWindowCoordinates(WC);
      If T0<>Time then
        begin
        If Animation then
          begin
          Window(1, 2, 63, 19); TextAttr:=7;
          GoToXY(25, 8); Write (OFVT[0]:1); ClrEol;
          NRB:=1;
          For i:=1 to NumberOfPositions do
            begin
              For j:=1 to P[i].Value do
                begin FastWriteWindow('█', 5, 2*NRB+1, White); inc(NRB); end;
              if i mod 2=0 then begin GoToXY(2*i+1,6); Write(i:1); end;
            end;
          GoToXY(1,3); ClrEol;
          For i:=1 to NumberOfRobots do
            FastWriteWindow ('@', 3, 2*RobotCoordInPos(i,delta)+1, $74);
          For i:=1  to NumberOfDetails do
            if Detail(i,timeD)=Critical then
              FastWriteWindow
                ('█', 5, D[i].Oper.Pos*2+1, LightRed+Blink);
          TextAttr:=$20;
          Case State of
            1: TraceSections;
            2: TraceDetails;
            3: TraceRobots;
          end;
          FastWrite(Long2Str(Cycle),3,74,$1F);
          FastWrite(Long2Str(Time),4,74,$1F);
          end
                     else
          TraceWhenNotAnimation;
          T0:=Time;
        end;
    RestoreWindowCoordinates(WC);
  end;

begin
  TraceKind:=TextTrace;
end.
