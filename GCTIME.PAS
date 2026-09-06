Unit GCTime;
  interface
  Uses TPCRT, TPEdit, TPString, GCInter;
  Procedure PutTimeScale (TimeScale: real);
  Procedure GetTimeScale (var TimeScale: real);

  implementation

  Procedure PutTimeScale (TimeScale: real);
    begin
      If Animation then FastWrite(Pad(Real2Str(TimeScale,1,1),8),5,73,$1F);
    end;

  Procedure GetTimeScale (var TimeScale: real);
    var
      Escaped: boolean;
      DT1: real;
    begin
      If Animation then
        begin
        DT1:=0;
        If AutoTimeRegime then TimeScale:=0;
        ReadReal('Масштаб: ', 5, 64, 6, $1F, $1F, 1, -1, 1000/DelayTimeMin, Escaped, TimeScale);
        ReadReal('Задержка: ', 6, 64, 6, $1F, $1F, 2, 0, 100, Escaped, DT1);
        If TimeScale=0 then DelayTime:=DelayTimeMin
                       else DelayTime:=Round(1000/TimeScale);
        inc(DelayTime, Round(DT1*1000));
        If TimeScale<>0 then TimeScale:=1000/DelayTime;
        PutTimeScale (TimeScale);
        AutoTimeRegime:=TimeScale=0;
        end;
    end;

begin end.
