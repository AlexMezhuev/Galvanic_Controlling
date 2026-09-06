Unit GCMenu;
  interface
  uses TPCRT, GCInter, GC_IF, GCTime, GCTrace;
  procedure KeyControl;

  implementation
    procedure KeyControl;
      var ch: char;
      begin
      If DelayTimeMin=0 then Exit; {Installation}
      If KeyPressed then
        begin
          Repeat ch:=ReadKey until ch<>#0;
          Case ch of
            #27, #45:
              Terminate (ch);
            #108:
              begin
              Animation:=Not Animation;
              InitScreen(Animation);
              end;
            else if Animation then
              case ch of
              #64:
                begin
                TextBackGround (Black); Window(1, 19, 63, 25); ClrScr;
                TextBackGround (Blue);  Window(64, 19, 80, 25); ClrScr;
                If State=3 then State:=0
                           else
                  begin
                  inc (State);
                  Window(1, SA[State].Y, 80, 25); TextAttr:=$2F; ClrScr;
                  Write (SA[State].Name:43);
                  end;
                inc (T0);
                end;
              #65: GetTimeScale(TimeScale);
              #75: If P0>7 then dec (P0, 7);
              #77: If P0<MaxRS-7 then inc (P0, 7);
              end;
          end;
        end;
    end;

begin end.