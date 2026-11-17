unit Aegis.Generics.Collections;

// Reference-counted collections for standard Delphi: IList<T>, IDictionary<K,V> and ISet<T> with the classes TList<T>,
// TDictionary<K,V> and THashSet<T>. Every collection is an IEnumerable<T>, so System.Linq can query all of them.
//
//   var Numbers := TList<Integer>.New([1, 2, 3]);     // IList<Integer>, freed with its last reference
//
// Lists, dictionaries and sets keep insertion order, so enumerating them is deterministic. Enumerators are live: they read
// the collection while they walk it. Keys and Values of a dictionary are snapshots.

interface

uses
  System.SysUtils, System.Generics.Collections, System.Generics.Defaults;

type
  TPair<K, V> = record
    Key: K;
    Value: V;
    constructor Create(const AKey: K; const AValue: V);
  end;

  IList<T> = interface(IEnumerable<T>)
    function GetCount: Integer;
    function GetItem(Index: Integer): T;
    procedure SetItem(Index: Integer; const Value: T);
    procedure Add(const Value: T); overload;
    procedure Add(const Values: array of T); overload;
    procedure Insert(Index: Integer; const Value: T);
    function IndexOf(const Value: T): Integer;
    function Contains(const Value: T): Boolean;
    function Remove(const Value: T): Boolean;
    procedure Delete(Index: Integer);
    procedure Clear;
    property Count: Integer read GetCount;
    property Items[Index: Integer]: T read GetItem write SetItem; default;
  end;

  ISet<T> = interface(IEnumerable<T>)
    function GetCount: Integer;
    function Add(const Value: T): Boolean;
    function Contains(const Value: T): Boolean;
    function Remove(const Value: T): Boolean;
    procedure Clear;
    property Count: Integer read GetCount;
  end;

  IDictionary<K, V> = interface(IEnumerable<TPair<K, V>>)
    function GetCount: Integer;
    function GetItem(const Key: K): V;
    procedure SetItem(const Key: K; const Value: V);
    function GetKeys: IList<K>;
    function GetValues: IList<V>;
    procedure Add(const Key: K; const Value: V);
    function TryGetValue(const Key: K; out Value: V): Boolean;
    function ContainsKey(const Key: K): Boolean;
    function Remove(const Key: K): Boolean;
    procedure Clear;
    property Count: Integer read GetCount;
    property Items[const Key: K]: V read GetItem write SetItem; default;
    property Keys: IList<K> read GetKeys;
    property Values: IList<V> read GetValues;
  end;

  // Walks a Delphi list by index; keeps the owning collection alive while the walk lasts.
  TListEnumerator<T> = class(TInterfacedObject, IEnumerator, IEnumerator<T>)
  private
    FOwner: IInterface;
    FList: System.Generics.Collections.TList<T>;
    FIndex: Integer;
  protected
    function GetCurrentT: T;
    function GetCurrent: TObject;
    function IEnumerator<T>.GetCurrent = GetCurrentT;
  public
    constructor Create(const AOwner: IInterface; AList: System.Generics.Collections.TList<T>);
    function MoveNext: Boolean;
    procedure Reset;
  end;

  TList<T> = class(TInterfacedObject, IEnumerable, IEnumerable<T>, IList<T>)
  private
    FItems: System.Generics.Collections.TList<T>;
    function GetCount: Integer;
    function GetItem(Index: Integer): T;
    procedure SetItem(Index: Integer; const Value: T);
    function GetEnumeratorT: IEnumerator<T>;
    function GetEnumerator: IEnumerator;
    function IEnumerable<T>.GetEnumerator = GetEnumeratorT;
    function IList<T>.GetEnumerator = GetEnumeratorT;
  public
    constructor Create;
    destructor Destroy; override;
    class function New: IList<T>; overload; static;
    class function New(const Values: array of T): IList<T>; overload; static;
    procedure Add(const Value: T); overload;
    procedure Add(const Values: array of T); overload;
    procedure Insert(Index: Integer; const Value: T);
    function IndexOf(const Value: T): Integer;
    function Contains(const Value: T): Boolean;
    function Remove(const Value: T): Boolean;
    procedure Delete(Index: Integer);
    procedure Clear;
  end;

  THashSet<T> = class(TInterfacedObject, IEnumerable, IEnumerable<T>, ISet<T>)
  private
    FItems: System.Generics.Collections.TList<T>;
    FIndex: System.Generics.Collections.TDictionary<T, Integer>;
    function GetCount: Integer;
    function GetEnumeratorT: IEnumerator<T>;
    function GetEnumerator: IEnumerator;
    function IEnumerable<T>.GetEnumerator = GetEnumeratorT;
    function ISet<T>.GetEnumerator = GetEnumeratorT;
    procedure Reindex;
  public
    constructor Create;
    destructor Destroy; override;
    class function New: ISet<T>; overload; static;
    class function New(const Values: array of T): ISet<T>; overload; static;
    function Add(const Value: T): Boolean;
    function Contains(const Value: T): Boolean;
    function Remove(const Value: T): Boolean;
    procedure Clear;
  end;

  TDictionary<K, V> = class(TInterfacedObject, IEnumerable, IEnumerable<TPair<K, V>>, IDictionary<K, V>)
  private
    FPairs: System.Generics.Collections.TList<TPair<K, V>>;
    FIndex: System.Generics.Collections.TDictionary<K, Integer>;
    function GetCount: Integer;
    function GetItem(const Key: K): V;
    procedure SetItem(const Key: K; const Value: V);
    function GetKeys: IList<K>;
    function GetValues: IList<V>;
    function GetEnumeratorT: IEnumerator<TPair<K, V>>;
    function GetEnumerator: IEnumerator;
    function IEnumerable<TPair<K, V>>.GetEnumerator = GetEnumeratorT;
    function IDictionary<K, V>.GetEnumerator = GetEnumeratorT;
    procedure Reindex;
  public
    constructor Create;
    destructor Destroy; override;
    class function New: IDictionary<K, V>; static;
    procedure Add(const Key: K; const Value: V);
    function TryGetValue(const Key: K; out Value: V): Boolean;
    function ContainsKey(const Key: K): Boolean;
    function Remove(const Key: K): Boolean;
    procedure Clear;
  end;

implementation

{ TPair<K, V> }

constructor TPair<K, V>.Create(const AKey: K; const AValue: V);
begin
  Key := AKey;
  Value := AValue;
end;

{ TListEnumerator<T> }

constructor TListEnumerator<T>.Create(const AOwner: IInterface; AList: System.Generics.Collections.TList<T>);
begin
  inherited Create;
  FOwner := AOwner;
  FList := AList;
  FIndex := -1;
end;

function TListEnumerator<T>.GetCurrentT: T;
begin
  Result := FList[FIndex];
end;

function TListEnumerator<T>.GetCurrent: TObject;
begin
  Result := nil;
end;

function TListEnumerator<T>.MoveNext: Boolean;
begin
  Inc(FIndex);
  Result := FIndex < FList.Count;
end;

procedure TListEnumerator<T>.Reset;
begin
  FIndex := -1;
end;

{ TList<T> }

constructor TList<T>.Create;
begin
  inherited Create;
  FItems := System.Generics.Collections.TList<T>.Create;
end;

destructor TList<T>.Destroy;
begin
  FItems.Free;
  inherited;
end;

class function TList<T>.New: IList<T>;
begin
  Result := TList<T>.Create;
end;

class function TList<T>.New(const Values: array of T): IList<T>;
begin
  Result := TList<T>.Create;
  Result.Add(Values);
end;

function TList<T>.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TList<T>.GetItem(Index: Integer): T;
begin
  Result := FItems[Index];
end;

procedure TList<T>.SetItem(Index: Integer; const Value: T);
begin
  FItems[Index] := Value;
end;

function TList<T>.GetEnumeratorT: IEnumerator<T>;
begin
  Result := TListEnumerator<T>.Create(Self, FItems);
end;

function TList<T>.GetEnumerator: IEnumerator;
begin
  Result := GetEnumeratorT;
end;

procedure TList<T>.Add(const Value: T);
begin
  FItems.Add(Value);
end;

procedure TList<T>.Add(const Values: array of T);
begin
  FItems.AddRange(Values);
end;

procedure TList<T>.Insert(Index: Integer; const Value: T);
begin
  FItems.Insert(Index, Value);
end;

function TList<T>.IndexOf(const Value: T): Integer;
begin
  Result := FItems.IndexOf(Value);
end;

function TList<T>.Contains(const Value: T): Boolean;
begin
  Result := FItems.IndexOf(Value) >= 0;
end;

function TList<T>.Remove(const Value: T): Boolean;
var
  Index: Integer;
begin
  Index := FItems.IndexOf(Value);
  Result := Index >= 0;
  if Result then
    FItems.Delete(Index);
end;

procedure TList<T>.Delete(Index: Integer);
begin
  FItems.Delete(Index);
end;

procedure TList<T>.Clear;
begin
  FItems.Clear;
end;

{ THashSet<T> }

constructor THashSet<T>.Create;
begin
  inherited Create;
  FItems := System.Generics.Collections.TList<T>.Create;
  FIndex := System.Generics.Collections.TDictionary<T, Integer>.Create;
end;

destructor THashSet<T>.Destroy;
begin
  FIndex.Free;
  FItems.Free;
  inherited;
end;

class function THashSet<T>.New: ISet<T>;
begin
  Result := THashSet<T>.Create;
end;

class function THashSet<T>.New(const Values: array of T): ISet<T>;
var
  Value: T;
begin
  Result := THashSet<T>.Create;
  for Value in Values do
    Result.Add(Value);
end;

function THashSet<T>.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function THashSet<T>.GetEnumeratorT: IEnumerator<T>;
begin
  Result := TListEnumerator<T>.Create(Self, FItems);
end;

function THashSet<T>.GetEnumerator: IEnumerator;
begin
  Result := GetEnumeratorT;
end;

procedure THashSet<T>.Reindex;
var
  I: Integer;
begin
  FIndex.Clear;
  for I := 0 to FItems.Count - 1 do
    FIndex.Add(FItems[I], I);
end;

function THashSet<T>.Add(const Value: T): Boolean;
begin
  Result := not FIndex.ContainsKey(Value);
  if Result then
  begin
    FIndex.Add(Value, FItems.Count);
    FItems.Add(Value);
  end;
end;

function THashSet<T>.Contains(const Value: T): Boolean;
begin
  Result := FIndex.ContainsKey(Value);
end;

function THashSet<T>.Remove(const Value: T): Boolean;
var
  Index: Integer;
begin
  Result := FIndex.TryGetValue(Value, Index);
  if Result then
  begin
    FItems.Delete(Index);
    Reindex;
  end;
end;

procedure THashSet<T>.Clear;
begin
  FItems.Clear;
  FIndex.Clear;
end;

{ TDictionary<K, V> }

constructor TDictionary<K, V>.Create;
begin
  inherited Create;
  FPairs := System.Generics.Collections.TList<TPair<K, V>>.Create;
  FIndex := System.Generics.Collections.TDictionary<K, Integer>.Create;
end;

destructor TDictionary<K, V>.Destroy;
begin
  FIndex.Free;
  FPairs.Free;
  inherited;
end;

class function TDictionary<K, V>.New: IDictionary<K, V>;
begin
  Result := TDictionary<K, V>.Create;
end;

function TDictionary<K, V>.GetCount: Integer;
begin
  Result := FPairs.Count;
end;

function TDictionary<K, V>.GetItem(const Key: K): V;
var
  Index: Integer;
begin
  if not FIndex.TryGetValue(Key, Index) then
    raise EListError.Create('The key is not in the dictionary');
  Result := FPairs[Index].Value;
end;

procedure TDictionary<K, V>.SetItem(const Key: K; const Value: V);
var
  Index: Integer;
begin
  if FIndex.TryGetValue(Key, Index) then
    FPairs[Index] := TPair<K, V>.Create(Key, Value)
  else
    Add(Key, Value);
end;

function TDictionary<K, V>.GetKeys: IList<K>;
var
  Pair: TPair<K, V>;
begin
  Result := TList<K>.New;
  for Pair in FPairs do
    Result.Add(Pair.Key);
end;

function TDictionary<K, V>.GetValues: IList<V>;
var
  Pair: TPair<K, V>;
begin
  Result := TList<V>.New;
  for Pair in FPairs do
    Result.Add(Pair.Value);
end;

function TDictionary<K, V>.GetEnumeratorT: IEnumerator<TPair<K, V>>;
begin
  Result := TListEnumerator<TPair<K, V>>.Create(Self, FPairs);
end;

function TDictionary<K, V>.GetEnumerator: IEnumerator;
begin
  Result := GetEnumeratorT;
end;

procedure TDictionary<K, V>.Reindex;
var
  I: Integer;
begin
  FIndex.Clear;
  for I := 0 to FPairs.Count - 1 do
    FIndex.Add(FPairs[I].Key, I);
end;

procedure TDictionary<K, V>.Add(const Key: K; const Value: V);
begin
  if FIndex.ContainsKey(Key) then
    raise EListError.Create('Duplicate key');
  FIndex.Add(Key, FPairs.Count);
  FPairs.Add(TPair<K, V>.Create(Key, Value));
end;

function TDictionary<K, V>.TryGetValue(const Key: K; out Value: V): Boolean;
var
  Index: Integer;
begin
  Result := FIndex.TryGetValue(Key, Index);
  if Result then
    Value := FPairs[Index].Value
  else
    Value := Default(V);
end;

function TDictionary<K, V>.ContainsKey(const Key: K): Boolean;
begin
  Result := FIndex.ContainsKey(Key);
end;

function TDictionary<K, V>.Remove(const Key: K): Boolean;
var
  Index: Integer;
begin
  Result := FIndex.TryGetValue(Key, Index);
  if Result then
  begin
    FPairs.Delete(Index);
    Reindex;
  end;
end;

procedure TDictionary<K, V>.Clear;
begin
  FPairs.Clear;
  FIndex.Clear;
end;

end.
