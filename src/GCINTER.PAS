Unit GCInter;
  interface
  Const
    MaxRS=24;
    MaxD=7;
    MaxStages=21;
    MaxSupportOp=25;
    MaxRobots=2;
    CRLF=#10+#13;
    SA: array [0..3] of record Name: string[8]; Y: byte; end=
          ((Name:'';Y:19),        (Name:'“ç áâª¨';Y:21),
           (Name:' „¥â «¨';Y:19), (Name:' ®¡®âë';Y:20));
  Type
    byteset=set of byte;
    SectionStateType=(free, taken);
    PositionType=record
      Value, Fillness, ContDet, Colour: byte;
      Coord: real;
    end;
    DetailStateType=
      (Absent, NotTreatmented, IsTreatmented, HadBeenTreatmented, Critical,
       Completed, Carried);
    SupportOpType=record
      Pos, PRTY: byte;
      Name: string;
    end;
    OperType=record
      Number, Pos: byte;
      MinDuration, MaxDuration: longint;
    end;
    DetailTreatmentType=record
      Oper: OperType;
      Stage: byte;
      Start: longint;
      C: word;
      ReglBreach: array [0..1] of word;
    end;
    RobotStateType=object
      HorCoord: real;
      DestP: byte;
      Element, VertCoord, HorDir, VertDir: shortint;
      RestTravelTime {for DetectAutoTime}, RestStopVertTravelTime: longint{eger};
      Busy, WithLoad: boolean;
      SSTime: longint;
    end;
    CarryCommandType=record
      Det, SourcePos, DestPos, CurrentAimPos: byte;
    end;
    CallTransportType=array [1..MaxRobots] of
      record
        PresentFlag, FutureFlag: boolean;
        FromPos, Det: byte;
        TimeUntilCall: longint;
      end;
    ChargeType=array [0..MaxD] of
      record
        Det: byte;
        MinTimeFromPrevious, Start: longint;
      end;
    ProgramList=^ProgramType;
    ProgramType=record
      Command: char;
      DelayTime: longint;
      Pos, Detail, Stage: byte;
      Next: ProgramList;
t0,t1: longint;
    end;
    BreachList=^BreachListType;
    BreachListType=record
      Det, Pos: byte;
      exceedence: word;
      percent: real;
      Next: BreachList;
    end;

  Var
    D: array [0..MaxD] of DetailTreatmentType;
    Op: array [1..MaxD, 0..MaxStages+1] of OperType;
    P: array [1..MaxRS] of PositionType;
    R: array [1..MaxRobots] of RobotStateType;
    RobotStopTime: array [1..3] of integer;
    RobotZones: array [1..MaxRobots] of byteset;
    LoadPosition, UnloadPosition: byte;
    CC: array [1..MaxRobots] of CarryCommandType;
    SupportOp: array [1..MaxSupportOp] of SupportOpType;
    CT: CallTransportType;
    CalcTimeParm: array [1..3] of longint;
    Charge: ChargeType;
    Left, Right, NewEl: array [1..MaxRobots] of ProgramList;
    OFVT: array [0..1] of longint;
    B_Left, B_Right, B_NewEl: BreachList;
    Animation, AutoTimeRegime: boolean;
    ch: char;
    NumberOfPositions, PositionNum, NumberOfDetails, Det, NumberOfRobots,
    NumberOfSupportOp, P0, StartColor, State: byte;
    Cycle, DelayTime, DelayTimeMin: word;
    busyRT, Time, timeD, TimeInc, T0, VertTravelTime: longint;
    delta, HT, RobotHorSpeed, RobotVertSpeed, TimeScale: real;
    Process, StartCharge: string;
    StartScreen: Pointer;
    f, f_set: text;
    TraceKind: (TextTrace, GraphicTrace);

  implementation

begin end.
