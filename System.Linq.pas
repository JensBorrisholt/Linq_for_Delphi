unit System.Linq;

// LINQ for standard Delphi: query operators over every IEnumerable<T>. A query is lazy and runs when it is enumerated.
//
// Delphi has neither helpers for interfaces nor generic helpers, so a sequence enters a query through Linq.From; the
// operators are methods of the record TQuery<T> and chain from there. Delphi cannot infer the element type of the
// collection, so Linq.From names it:
//
//   Names := Linq.From<TPerson>(Staff)
//     .Where(function(P: TPerson): Boolean begin Result := P.Age > 30 end)
//     .OrderBy<string>(function(P: TPerson): string begin Result := P.Name end)
//     .Select<string>(function(P: TPerson): string begin Result := P.Name end);
//
// A TQuery<T> converts to and from IEnumerable<T>, so a query can be stored, passed on and enumerated with for-in.
// Delphi cannot infer a generic argument from an anonymous method either, so Select, Sum, OrderBy ... name it: Select<string>.

interface

uses
  System.SysUtils, System.TypInfo, System.Rtti, System.Generics.Defaults, System.Generics.Collections,
  Aegis.Generics.Collections;

type
  // One pass over a sequence: returns False at the end.
  TMover<T> = reference to function(out Value: T): Boolean;
  // Starts a pass; every enumeration of a query opens its own.
  TOpener<T> = reference to function: TMover<T>;

  TMoverEnumerator<T> = class(TInterfacedObject, IEnumerator, IEnumerator<T>)
  private
    FMove: TMover<T>;
    FCurrent: T;
  protected
    function GetCurrentT: T;
    function GetCurrent: TObject;
    function IEnumerator<T>.GetCurrent = GetCurrentT;
  public
    constructor Create(const AMove: TMover<T>);
    function MoveNext: Boolean;
    procedure Reset;
  end;

  TOpenerEnumerable<T> = class(TInterfacedObject, IEnumerable, IEnumerable<T>)
  private
    FOpen: TOpener<T>;
    function GetEnumeratorT: IEnumerator<T>;
    function GetEnumerator: IEnumerator;
    function IEnumerable<T>.GetEnumerator = GetEnumeratorT;
  public
    constructor Create(const AOpen: TOpener<T>);
  end;

  // Sum and Average of any integer or floating point type.
  TNumeric = class
  public
    class function Sum<N>(const Items: IEnumerable<N>): N; static;
    class function Average<N>(const Items: IEnumerable<N>): Double; static;
  end;

  TQuery<T> = record
  private
    FSource: IEnumerable<T>;
    class function Collect(const Source: IEnumerable<T>): TArray<T>; static;
    function Sorted<K>(const KeySelector: TFunc<T, K>; Descending: Boolean): TQuery<T>;
  public
    class operator Implicit(const Source: IEnumerable<T>): TQuery<T>;
    class operator Implicit(const Source: TQuery<T>): IEnumerable<T>;
    function GetEnumerator: IEnumerator<T>;
    // filtering and projection
    function Where(const Predicate: TPredicate<T>): TQuery<T>;
    function Select<R>(const Selector: TFunc<T, R>): TQuery<R>;
    function SelectMany<R>(const Selector: TFunc<T, IEnumerable<R>>): TQuery<R>;
    function Zip<B, R>(const Other: IEnumerable<B>; const Combine: TFunc<T, B, R>): TQuery<R>;
    // partitioning
    function Take(ACount: Integer): TQuery<T>;
    function Skip(ACount: Integer): TQuery<T>;
    function TakeWhile(const Predicate: TPredicate<T>): TQuery<T>;
    function SkipWhile(const Predicate: TPredicate<T>): TQuery<T>;
    // ordering and sets
    function OrderBy<K>(const KeySelector: TFunc<T, K>): TQuery<T>;
    function OrderByDescending<K>(const KeySelector: TFunc<T, K>): TQuery<T>;
    function Reverse: TQuery<T>;
    function Distinct: TQuery<T>;
    function Concat(const Other: IEnumerable<T>): TQuery<T>;
    function Union(const Other: IEnumerable<T>): TQuery<T>;
    function Intersect(const Other: IEnumerable<T>): TQuery<T>;
    function &Except(const Other: IEnumerable<T>): TQuery<T>;
    // elements
    function First: T; overload;
    function First(const Predicate: TPredicate<T>): T; overload;
    function FirstOrDefault: T; overload;
    function FirstOrDefault(const Predicate: TPredicate<T>): T; overload;
    function Last: T; overload;
    function Last(const Predicate: TPredicate<T>): T; overload;
    function LastOrDefault: T; overload;
    function LastOrDefault(const Predicate: TPredicate<T>): T; overload;
    function Single: T;
    function ElementAt(Index: Integer): T;
    // quantifiers and counting
    function Any: Boolean; overload;
    function Any(const Predicate: TPredicate<T>): Boolean; overload;
    function All(const Predicate: TPredicate<T>): Boolean;
    function Contains(const Value: T): Boolean;
    function Count: Integer; overload;
    function Count(const Predicate: TPredicate<T>): Integer; overload;
    // numbers
    function Sum: T; overload;
    function Sum<R>(const Selector: TFunc<T, R>): R; overload;
    function Average: Double; overload;
    function Average<R>(const Selector: TFunc<T, R>): Double; overload;
    function Min: T; overload;
    function Min<R>(const Selector: TFunc<T, R>): R; overload;
    function Max: T; overload;
    function Max<R>(const Selector: TFunc<T, R>): R; overload;
    function Aggregate<A>(const Seed: A; const Func: TFunc<A, T, A>): A;
    // materialising
    function ToList: IList<T>;
    function ToArray: TArray<T>;
    function ToHashSet: ISet<T>;
    function ToDictionary<K>(const KeySelector: TFunc<T, K>): IDictionary<K, T>; overload;
    function ToDictionary<K, V>(const KeySelector: TFunc<T, K>; const ValueSelector: TFunc<T, V>): IDictionary<K, V>; overload;
    procedure ForEach(const Action: TProc<T>);
  end;

  // The entrance of a query: Linq.From(<any collection>).
  Linq = class
  public
    class function From<T>(const Source: IEnumerable<T>): TQuery<T>; overload; static;
    class function From<T>(const Source: IList<T>): TQuery<T>; overload; static;
    class function From<T>(const Source: ISet<T>): TQuery<T>; overload; static;
    class function From<K, V>(const Source: IDictionary<K, V>): TQuery<TPair<K, V>>; overload; static;
    class function From<T>(const Source: TArray<T>): TQuery<T>; overload; static;
  end;

  // Enumerable.Range, Repeat and Empty
  Enumerable = class
  public
    class function Range(Start, Count: Integer): TQuery<Integer>; static;
    class function &Repeat<T>(const Value: T; Count: Integer): TQuery<T>; static;
    class function Empty<T>: TQuery<T>; static;
  end;

implementation

{ TMoverEnumerator<T> }

constructor TMoverEnumerator<T>.Create(const AMove: TMover<T>);
begin
  inherited Create;
  FMove := AMove;
end;

function TMoverEnumerator<T>.GetCurrentT: T;
begin
  Result := FCurrent;
end;

function TMoverEnumerator<T>.GetCurrent: TObject;
begin
  Result := nil;
end;

function TMoverEnumerator<T>.MoveNext: Boolean;
begin
  Result := FMove(FCurrent);
end;

procedure TMoverEnumerator<T>.Reset;
begin
  raise ENotSupportedException.Create('A query enumerator cannot be reset');
end;

{ TOpenerEnumerable<T> }

constructor TOpenerEnumerable<T>.Create(const AOpen: TOpener<T>);
begin
  inherited Create;
  FOpen := AOpen;
end;

function TOpenerEnumerable<T>.GetEnumeratorT: IEnumerator<T>;
begin
  Result := TMoverEnumerator<T>.Create(FOpen());
end;

function TOpenerEnumerable<T>.GetEnumerator: IEnumerator;
begin
  Result := GetEnumeratorT;
end;

{ TNumeric }

class function TNumeric.Sum<N>(const Items: IEnumerable<N>): N;
var
  Info: PTypeInfo;
  Whole: Int64;
  Fraction: Extended;
  Value: N;
  Total: TValue;
begin
  Info := TypeInfo(N);
  if Info.Kind = tkFloat then
  begin
    Fraction := 0;
    for Value in Items do
      Fraction := Fraction + TValue.From<N>(Value).AsExtended;
    Total := TValue.From<Extended>(Fraction);
  end
  else
  begin
    Whole := 0;
    for Value in Items do
      Whole := Whole + TValue.From<N>(Value).AsInt64;
    Total := TValue.From<Int64>(Whole);
  end;
  Result := Total.Cast(Info).AsType<N>;
end;

class function TNumeric.Average<N>(const Items: IEnumerable<N>): Double;
var
  Total: Extended;
  Number: Integer;
  Value: N;
begin
  Total := 0;
  Number := 0;
  for Value in Items do
  begin
    Total := Total + TValue.From<N>(Value).AsExtended;
    Inc(Number);
  end;
  if Number = 0 then
    raise EInvalidOpException.Create('Sequence contains no elements');
  Result := Total / Number;
end;

{ TQuery<T> }

class operator TQuery<T>.Implicit(const Source: IEnumerable<T>): TQuery<T>;
begin
  Result.FSource := Source;
end;

class operator TQuery<T>.Implicit(const Source: TQuery<T>): IEnumerable<T>;
begin
  Result := Source.FSource;
end;

function TQuery<T>.GetEnumerator: IEnumerator<T>;
begin
  Result := FSource.GetEnumerator;
end;

class function TQuery<T>.Collect(const Source: IEnumerable<T>): TArray<T>;
var
  Value: T;
  Used: Integer;
begin
  Used := 0;
  for Value in Source do
  begin
    if Used = Length(Result) then
      SetLength(Result, Used * 2 + 4);
    Result[Used] := Value;
    Inc(Used);
  end;
  SetLength(Result, Used);
end;

function TQuery<T>.Where(const Predicate: TPredicate<T>): TQuery<T>;
var
  Source: IEnumerable<T>;
begin
  Source := FSource;
  Result.FSource := TOpenerEnumerable<T>.Create(
    function: TMover<T>
    var
      E: IEnumerator<T>;
    begin
      E := Source.GetEnumerator;
      Result := function(out Value: T): Boolean
        begin
          while E.MoveNext do
          begin
            Value := E.Current;
            if Predicate(Value) then
              Exit(True);
          end;
          Result := False;
        end;
    end);
end;

function TQuery<T>.Select<R>(const Selector: TFunc<T, R>): TQuery<R>;
var
  Source: IEnumerable<T>;
begin
  Source := FSource;
  Result.FSource := TOpenerEnumerable<R>.Create(
    function: TMover<R>
    var
      E: IEnumerator<T>;
    begin
      E := Source.GetEnumerator;
      Result := function(out Value: R): Boolean
        begin
          Result := E.MoveNext;
          if Result then
            Value := Selector(E.Current);
        end;
    end);
end;

function TQuery<T>.SelectMany<R>(const Selector: TFunc<T, IEnumerable<R>>): TQuery<R>;
var
  Source: IEnumerable<T>;
begin
  Source := FSource;
  Result.FSource := TOpenerEnumerable<R>.Create(
    function: TMover<R>
    var
      Outer: IEnumerator<T>;
      Inner: IEnumerator<R>;
    begin
      Outer := Source.GetEnumerator;
      Inner := nil;
      Result := function(out Value: R): Boolean
        begin
          while True do
          begin
            if Inner <> nil then
            begin
              if Inner.MoveNext then
              begin
                Value := Inner.Current;
                Exit(True);
              end;
              Inner := nil;
            end;
            if not Outer.MoveNext then
              Exit(False);
            Inner := Selector(Outer.Current).GetEnumerator;
          end;
        end;
    end);
end;

function TQuery<T>.Zip<B, R>(const Other: IEnumerable<B>; const Combine: TFunc<T, B, R>): TQuery<R>;
var
  Source: IEnumerable<T>;
begin
  Source := FSource;
  Result.FSource := TOpenerEnumerable<R>.Create(
    function: TMover<R>
    var
      EA: IEnumerator<T>;
      EB: IEnumerator<B>;
    begin
      EA := Source.GetEnumerator;
      EB := Other.GetEnumerator;
      Result := function(out Value: R): Boolean
        begin
          Result := EA.MoveNext and EB.MoveNext;
          if Result then
            Value := Combine(EA.Current, EB.Current);
        end;
    end);
end;

function TQuery<T>.Take(ACount: Integer): TQuery<T>;
var
  Source: IEnumerable<T>;
begin
  Source := FSource;
  Result.FSource := TOpenerEnumerable<T>.Create(
    function: TMover<T>
    var
      E: IEnumerator<T>;
      Taken: Integer;
    begin
      E := Source.GetEnumerator;
      Taken := 0;
      Result := function(out Value: T): Boolean
        begin
          Result := (Taken < ACount) and E.MoveNext;
          if Result then
          begin
            Inc(Taken);
            Value := E.Current;
          end;
        end;
    end);
end;

function TQuery<T>.Skip(ACount: Integer): TQuery<T>;
var
  Source: IEnumerable<T>;
begin
  Source := FSource;
  Result.FSource := TOpenerEnumerable<T>.Create(
    function: TMover<T>
    var
      E: IEnumerator<T>;
      Skipped: Boolean;
    begin
      E := Source.GetEnumerator;
      Skipped := False;
      Result := function(out Value: T): Boolean
        var
          I: Integer;
        begin
          if not Skipped then
          begin
            Skipped := True;
            for I := 1 to ACount do
              if not E.MoveNext then
                Break;
          end;
          Result := E.MoveNext;
          if Result then
            Value := E.Current;
        end;
    end);
end;

function TQuery<T>.TakeWhile(const Predicate: TPredicate<T>): TQuery<T>;
var
  Source: IEnumerable<T>;
begin
  Source := FSource;
  Result.FSource := TOpenerEnumerable<T>.Create(
    function: TMover<T>
    var
      E: IEnumerator<T>;
      Done: Boolean;
    begin
      E := Source.GetEnumerator;
      Done := False;
      Result := function(out Value: T): Boolean
        begin
          Result := False;
          if Done then
            Exit;
          if E.MoveNext and Predicate(E.Current) then
          begin
            Value := E.Current;
            Result := True;
          end
          else
            Done := True;
        end;
    end);
end;

function TQuery<T>.SkipWhile(const Predicate: TPredicate<T>): TQuery<T>;
var
  Source: IEnumerable<T>;
begin
  Source := FSource;
  Result.FSource := TOpenerEnumerable<T>.Create(
    function: TMover<T>
    var
      E: IEnumerator<T>;
      Skipping: Boolean;
    begin
      E := Source.GetEnumerator;
      Skipping := True;
      Result := function(out Value: T): Boolean
        begin
          while E.MoveNext do
          begin
            if Skipping and Predicate(E.Current) then
              Continue;
            Skipping := False;
            Value := E.Current;
            Exit(True);
          end;
          Result := False;
        end;
    end);
end;

// A stable sort by key, done when the first element is asked for.
function TQuery<T>.Sorted<K>(const KeySelector: TFunc<T, K>; Descending: Boolean): TQuery<T>;
var
  Source: IEnumerable<T>;
begin
  Source := FSource;
  Result.FSource := TOpenerEnumerable<T>.Create(
    function: TMover<T>
    var
      Items: TArray<T>;
      Keys: TArray<K>;
      Order: TArray<Integer>;
      Compare: IComparer<K>;
      I, Position: Integer;
    begin
      Items := Collect(Source);
      SetLength(Keys, Length(Items));
      SetLength(Order, Length(Items));
      for I := 0 to High(Items) do
      begin
        Keys[I] := KeySelector(Items[I]);
        Order[I] := I;
      end;
      Compare := TComparer<K>.Default;
      TArray.Sort<Integer>(Order, TComparer<Integer>.Construct(
        function(const A, B: Integer): Integer
        begin
          Result := Compare.Compare(Keys[A], Keys[B]);
          if Descending then
            Result := -Result;
          if Result = 0 then
            Result := A - B;
        end));
      Position := 0;
      Result := function(out Value: T): Boolean
        begin
          Result := Position < Length(Order);
          if Result then
          begin
            Value := Items[Order[Position]];
            Inc(Position);
          end;
        end;
    end);
end;

function TQuery<T>.OrderBy<K>(const KeySelector: TFunc<T, K>): TQuery<T>;
begin
  Result := Sorted<K>(KeySelector, False);
end;

function TQuery<T>.OrderByDescending<K>(const KeySelector: TFunc<T, K>): TQuery<T>;
begin
  Result := Sorted<K>(KeySelector, True);
end;

function TQuery<T>.Reverse: TQuery<T>;
var
  Source: IEnumerable<T>;
begin
  Source := FSource;
  Result.FSource := TOpenerEnumerable<T>.Create(
    function: TMover<T>
    var
      Items: TArray<T>;
      Position: Integer;
    begin
      Items := Collect(Source);
      Position := Length(Items);
      Result := function(out Value: T): Boolean
        begin
          Dec(Position);
          Result := Position >= 0;
          if Result then
            Value := Items[Position];
        end;
    end);
end;

function TQuery<T>.Distinct: TQuery<T>;
var
  Source: IEnumerable<T>;
begin
  Source := FSource;
  Result.FSource := TOpenerEnumerable<T>.Create(
    function: TMover<T>
    var
      E: IEnumerator<T>;
      Seen: ISet<T>;
    begin
      E := Source.GetEnumerator;
      Seen := THashSet<T>.New;
      Result := function(out Value: T): Boolean
        begin
          while E.MoveNext do
            if Seen.Add(E.Current) then
            begin
              Value := E.Current;
              Exit(True);
            end;
          Result := False;
        end;
    end);
end;

function TQuery<T>.Concat(const Other: IEnumerable<T>): TQuery<T>;
var
  Source: IEnumerable<T>;
begin
  Source := FSource;
  Result.FSource := TOpenerEnumerable<T>.Create(
    function: TMover<T>
    var
      E: IEnumerator<T>;
      OnSecond: Boolean;
    begin
      E := Source.GetEnumerator;
      OnSecond := False;
      Result := function(out Value: T): Boolean
        begin
          if not OnSecond then
          begin
            if E.MoveNext then
            begin
              Value := E.Current;
              Exit(True);
            end;
            OnSecond := True;
            E := Other.GetEnumerator;
          end;
          Result := E.MoveNext;
          if Result then
            Value := E.Current;
        end;
    end);
end;

function TQuery<T>.Union(const Other: IEnumerable<T>): TQuery<T>;
begin
  Result := Concat(Other).Distinct;
end;

function TQuery<T>.Intersect(const Other: IEnumerable<T>): TQuery<T>;
var
  Source: IEnumerable<T>;
begin
  Source := FSource;
  Result.FSource := TOpenerEnumerable<T>.Create(
    function: TMover<T>
    var
      E: IEnumerator<T>;
      Filter, Emitted: ISet<T>;
      Value: T;
    begin
      E := Source.GetEnumerator;
      Filter := THashSet<T>.New;
      for Value in Other do
        Filter.Add(Value);
      Emitted := THashSet<T>.New;
      Result := function(out Item: T): Boolean
        begin
          while E.MoveNext do
            if Filter.Contains(E.Current) and Emitted.Add(E.Current) then
            begin
              Item := E.Current;
              Exit(True);
            end;
          Result := False;
        end;
    end);
end;

function TQuery<T>.&Except(const Other: IEnumerable<T>): TQuery<T>;
var
  Source: IEnumerable<T>;
begin
  Source := FSource;
  Result.FSource := TOpenerEnumerable<T>.Create(
    function: TMover<T>
    var
      E: IEnumerator<T>;
      Filter, Emitted: ISet<T>;
      Value: T;
    begin
      E := Source.GetEnumerator;
      Filter := THashSet<T>.New;
      for Value in Other do
        Filter.Add(Value);
      Emitted := THashSet<T>.New;
      Result := function(out Item: T): Boolean
        begin
          while E.MoveNext do
            if not Filter.Contains(E.Current) and Emitted.Add(E.Current) then
            begin
              Item := E.Current;
              Exit(True);
            end;
          Result := False;
        end;
    end);
end;

function TQuery<T>.First: T;
var
  E: IEnumerator<T>;
begin
  E := FSource.GetEnumerator;
  if not E.MoveNext then
    raise EInvalidOpException.Create('Sequence contains no elements');
  Result := E.Current;
end;

function TQuery<T>.First(const Predicate: TPredicate<T>): T;
var
  Value: T;
begin
  for Value in FSource do
    if Predicate(Value) then
      Exit(Value);
  raise EInvalidOpException.Create('Sequence contains no matching element');
end;

function TQuery<T>.FirstOrDefault: T;
var
  E: IEnumerator<T>;
begin
  E := FSource.GetEnumerator;
  if E.MoveNext then
    Result := E.Current
  else
    Result := Default(T);
end;

function TQuery<T>.FirstOrDefault(const Predicate: TPredicate<T>): T;
var
  Value: T;
begin
  for Value in FSource do
    if Predicate(Value) then
      Exit(Value);
  Result := Default(T);
end;

function TQuery<T>.Last: T;
var
  Value: T;
  Found: Boolean;
begin
  Result := Default(T);
  Found := False;
  for Value in FSource do
  begin
    Result := Value;
    Found := True;
  end;
  if not Found then
    raise EInvalidOpException.Create('Sequence contains no elements');
end;

function TQuery<T>.Last(const Predicate: TPredicate<T>): T;
var
  Value: T;
  Found: Boolean;
begin
  Result := Default(T);
  Found := False;
  for Value in FSource do
    if Predicate(Value) then
    begin
      Result := Value;
      Found := True;
    end;
  if not Found then
    raise EInvalidOpException.Create('Sequence contains no matching element');
end;

function TQuery<T>.LastOrDefault: T;
var
  Value: T;
begin
  Result := Default(T);
  for Value in FSource do
    Result := Value;
end;

function TQuery<T>.LastOrDefault(const Predicate: TPredicate<T>): T;
var
  Value: T;
begin
  Result := Default(T);
  for Value in FSource do
    if Predicate(Value) then
      Result := Value;
end;

function TQuery<T>.Single: T;
var
  E: IEnumerator<T>;
begin
  E := FSource.GetEnumerator;
  if not E.MoveNext then
    raise EInvalidOpException.Create('Sequence contains no elements');
  Result := E.Current;
  if E.MoveNext then
    raise EInvalidOpException.Create('Sequence contains more than one element');
end;

function TQuery<T>.ElementAt(Index: Integer): T;
var
  Value: T;
  Position: Integer;
begin
  Position := 0;
  for Value in FSource do
  begin
    if Position = Index then
      Exit(Value);
    Inc(Position);
  end;
  raise EArgumentOutOfRangeException.Create('Index is out of range');
end;

function TQuery<T>.Any: Boolean;
begin
  Result := FSource.GetEnumerator.MoveNext;
end;

function TQuery<T>.Any(const Predicate: TPredicate<T>): Boolean;
var
  Value: T;
begin
  for Value in FSource do
    if Predicate(Value) then
      Exit(True);
  Result := False;
end;

function TQuery<T>.All(const Predicate: TPredicate<T>): Boolean;
var
  Value: T;
begin
  for Value in FSource do
    if not Predicate(Value) then
      Exit(False);
  Result := True;
end;

function TQuery<T>.Contains(const Value: T): Boolean;
var
  Item: T;
  Equal: IEqualityComparer<T>;
begin
  Equal := TEqualityComparer<T>.Default;
  for Item in FSource do
    if Equal.Equals(Item, Value) then
      Exit(True);
  Result := False;
end;

function TQuery<T>.Count: Integer;
var
  Value: T;
begin
  Result := 0;
  for Value in FSource do
    Inc(Result);
end;

function TQuery<T>.Count(const Predicate: TPredicate<T>): Integer;
var
  Value: T;
begin
  Result := 0;
  for Value in FSource do
    if Predicate(Value) then
      Inc(Result);
end;

function TQuery<T>.Sum: T;
begin
  Result := TNumeric.Sum<T>(FSource);
end;

function TQuery<T>.Sum<R>(const Selector: TFunc<T, R>): R;
begin
  Result := TNumeric.Sum<R>(Select<R>(Selector).FSource);
end;

function TQuery<T>.Average: Double;
begin
  Result := TNumeric.Average<T>(FSource);
end;

function TQuery<T>.Average<R>(const Selector: TFunc<T, R>): Double;
begin
  Result := TNumeric.Average<R>(Select<R>(Selector).FSource);
end;

function TQuery<T>.Min: T;
var
  Value: T;
  First: Boolean;
  Compare: IComparer<T>;
begin
  Result := Default(T);
  Compare := TComparer<T>.Default;
  First := True;
  for Value in FSource do
    if First or (Compare.Compare(Value, Result) < 0) then
    begin
      Result := Value;
      First := False;
    end;
  if First then
    raise EInvalidOpException.Create('Sequence contains no elements');
end;

function TQuery<T>.Min<R>(const Selector: TFunc<T, R>): R;
begin
  Result := Select<R>(Selector).Min;
end;

function TQuery<T>.Max: T;
var
  Value: T;
  First: Boolean;
  Compare: IComparer<T>;
begin
  Result := Default(T);
  Compare := TComparer<T>.Default;
  First := True;
  for Value in FSource do
    if First or (Compare.Compare(Value, Result) > 0) then
    begin
      Result := Value;
      First := False;
    end;
  if First then
    raise EInvalidOpException.Create('Sequence contains no elements');
end;

function TQuery<T>.Max<R>(const Selector: TFunc<T, R>): R;
begin
  Result := Select<R>(Selector).Max;
end;

function TQuery<T>.Aggregate<A>(const Seed: A; const Func: TFunc<A, T, A>): A;
var
  Value: T;
begin
  Result := Seed;
  for Value in FSource do
    Result := Func(Result, Value);
end;

function TQuery<T>.ToList: IList<T>;
var
  Value: T;
begin
  Result := TList<T>.New;
  for Value in FSource do
    Result.Add(Value);
end;

function TQuery<T>.ToArray: TArray<T>;
begin
  Result := Collect(FSource);
end;

function TQuery<T>.ToHashSet: ISet<T>;
var
  Value: T;
begin
  Result := THashSet<T>.New;
  for Value in FSource do
    Result.Add(Value);
end;

function TQuery<T>.ToDictionary<K>(const KeySelector: TFunc<T, K>): IDictionary<K, T>;
var
  Value: T;
begin
  Result := TDictionary<K, T>.New;
  for Value in FSource do
    Result.Add(KeySelector(Value), Value);
end;

function TQuery<T>.ToDictionary<K, V>(const KeySelector: TFunc<T, K>; const ValueSelector: TFunc<T, V>): IDictionary<K, V>;
var
  Value: T;
begin
  Result := TDictionary<K, V>.New;
  for Value in FSource do
    Result.Add(KeySelector(Value), ValueSelector(Value));
end;

procedure TQuery<T>.ForEach(const Action: TProc<T>);
var
  Value: T;
begin
  for Value in FSource do
    Action(Value);
end;

{ Linq }

class function Linq.From<T>(const Source: IEnumerable<T>): TQuery<T>;
begin
  Result.FSource := Source;
end;

class function Linq.From<T>(const Source: IList<T>): TQuery<T>;
begin
  Result.FSource := Source;
end;

class function Linq.From<T>(const Source: ISet<T>): TQuery<T>;
begin
  Result.FSource := Source;
end;

class function Linq.From<K, V>(const Source: IDictionary<K, V>): TQuery<TPair<K, V>>;
begin
  Result.FSource := Source;
end;

class function Linq.From<T>(const Source: TArray<T>): TQuery<T>;
begin
  Result.FSource := TOpenerEnumerable<T>.Create(
    function: TMover<T>
    var
      Position: Integer;
    begin
      Position := 0;
      Result := function(out Value: T): Boolean
        begin
          Result := Position < Length(Source);
          if Result then
          begin
            Value := Source[Position];
            Inc(Position);
          end;
        end;
    end);
end;

{ Enumerable }

class function Enumerable.Range(Start, Count: Integer): TQuery<Integer>;
begin
  Result.FSource := TOpenerEnumerable<Integer>.Create(
    function: TMover<Integer>
    var
      Position: Integer;
    begin
      Position := 0;
      Result := function(out Value: Integer): Boolean
        begin
          Result := Position < Count;
          if Result then
          begin
            Value := Start + Position;
            Inc(Position);
          end;
        end;
    end);
end;

class function Enumerable.&Repeat<T>(const Value: T; Count: Integer): TQuery<T>;
begin
  Result.FSource := TOpenerEnumerable<T>.Create(
    function: TMover<T>
    var
      Position: Integer;
    begin
      Position := 0;
      Result := function(out Item: T): Boolean
        begin
          Result := Position < Count;
          if Result then
          begin
            Item := Value;
            Inc(Position);
          end;
        end;
    end);
end;

class function Enumerable.Empty<T>: TQuery<T>;
begin
  Result.FSource := TOpenerEnumerable<T>.Create(
    function: TMover<T>
    begin
      Result := function(out Value: T): Boolean
        begin
          Result := False;
        end;
    end);
end;

end.
