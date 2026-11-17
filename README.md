# Linq for Delphi

LINQ for **standard Delphi**: lazy query operators (`Where`, `Select`, `OrderBy`, `Aggregate` ...) over lists, dictionaries,
sets and arrays, with its own reference-counted collections and three demo programs. No compiler extensions; built with
Delphi 13 (`dcc64`, and the IDE's `dcc32` for Win32).

## Contents

| File | What |
|---|---|
| `Aegis.Generics.Collections.pas` | Own reference-counted generics: `IList<T>`, `ISet<T>`, `IDictionary<K,V>` with `TList<T>`, `THashSet<T>`, `TDictionary<K,V>` and `New` factories. They keep insertion order, so enumeration is deterministic. |
| `System.Linq.pas` | The query operators as the record `TQuery<T>`, plus `Linq.From` and `Enumerable.Range/Repeat/Empty`. Queries are lazy, as in C#. |
| `LinqDemo\` | A tour: numbers, people (with `Models.pas`), a dictionary and ranges. |
| `CollectionsLinqDemo\` | `InventoryQueries`, `LazyQueries`, `OrdersPipeline`, `SetAnalytics`. |
| `AdvancedLinqDemo\` | `AggregateReport`, `SelectManyGroups`, `ToDictionaryIndex`, `ZipColumns`. |
| `build.cmd` | `build.cmd [run] [Folder\Demo ...]` builds into `bin\` and, with `run`, runs the demos (without waiting for ReadLn). |

## Demos

Each demo is one program (`.dpr`); run them from the IDE or with `build.cmd run <Folder\Demo>`.

**LinqDemo**: the tour. Four parts, one procedure each.

| Part | Shows |
|---|---|
| Numbers | `Where`, `Select`, `Aggregate`, `Any`, `All`, `First`, `Skip`, `Take`, `Count` on a list of 1 to 10. |
| People | A list of `TPerson` objects (`Models.pas`): filter, `OrderBy`, `OrderByDescending`, `Select`, `Average`, `Count`. |
| Dictionary | Querying an `IDictionary<string, Integer>` as a sequence of key/value pairs, and `Sum` over `Values`. |
| Ranges | `Enumerable.Range` and sorting strings. |

**CollectionsLinqDemo**: queries over the different collection types.

| Demo | Shows |
|---|---|
| `InventoryQueries` | A dictionary of stock levels: filter, sort by key, `Sum` of the values, `Count` of what is out of stock. |
| `LazyQueries` | Deferred execution: a query sees an element added after it was written, a `ToList` snapshot does not, and `Take` stops early. |
| `OrdersPipeline` | A list of records: filter unpaid orders, `OrderByDescending` on the amount, `Sum` and `Any`. |
| `SetAnalytics` | Two `ISet<Integer>`: `Intersect`, `Except` and `Union`. |

**AdvancedLinqDemo**: the operators that need a little more.

| Demo | Shows |
|---|---|
| `AggregateReport` | `Aggregate` three ways: a total, a maximum and a joined string, each with its own seed and result type. |
| `SelectManyGroups` | `SelectMany` flattens teams with their members into one list of names. |
| `ToDictionaryIndex` | `ToDictionary` with one selector (the record is the value) and with two (key and value chosen), then lookups with `TryGetValue`. |
| `ZipColumns` | `Zip` pairs two lists, here names and scores, and stops at the shorter. |

## Using it

```pascal
uses
  Aegis.Generics.Collections, System.Linq;

var Numbers := TList<Integer>.New([1, 2, 3, 4, 5, 6]);   // IList<Integer>, freed with its last reference

var Squares := Linq.From<Integer>(Numbers)
.Where
(
  function(N: Integer): Boolean
  begin
    Result := N mod 2 = 0;
  end
)
.Select<Integer>
(
  function(N: Integer): Integer
  begin
    Result := N * N;
  end
);

for var N in Squares do
  WriteLn(N);   // 4, 16, 36
```

## Lazy and immediate

An operator is either **lazy** or **immediate**.

A *lazy* operator (`Where`, `Select`, `Take`, `OrderBy` ...) does no work when you call it. It only describes the query and
returns it. The work happens when something *enumerates* the query: a `for ... in` loop, or an immediate operator such as
`Count` or `ToList`.

An *immediate* operator (`Count`, `Sum`, `First`, `ToList`, `ToArray` ...) runs the query at once and returns a value.

```pascal
var Numbers := TList<Integer>.New([1, 2, 3, 4]);

var Evens := Linq.From<Integer>(Numbers).Where     // lazy: nothing has run yet
(
  function(N: Integer): Boolean
  begin
    WriteLn('testing ', N);
    Result := N mod 2 = 0;
  end
);
WriteLn('query built');                            // prints before any "testing"

WriteLn(Evens.Count);                              // immediate: now it runs, prints "testing 1" .. "testing 4", then 2
```

**A lazy query sees the data as it is when it runs, not when it was written.** Enumerate it again and it runs again:

```pascal
var Evens := Linq.From<Integer>(Numbers).Where(...);   // 2, 4

Numbers.Add(6);
for var N in Evens do WriteLn(N);                      // 2, 4, 6: the new element is included
```

**A materialised result is a snapshot.** `ToList`, `ToArray`, `ToHashSet` and `ToDictionary` run the query once and keep the
answer, so later changes to the source do not reach it:

```pascal
var Snapshot := Evens.ToList;                          // runs now: 2, 4, 6

Numbers.Add(8);
Evens.Count;                                           // 4: the query runs again and sees the 8
Snapshot.Count;                                        // 3: the list was taken before the 8
```

**A lazy query stops as soon as it has enough.** `Take` and `First` do not read the rest of the source:

```pascal
var FirstTwo := Linq.From<Integer>(Numbers).Where(...).Take(2);   // the predicate is called for 1, 2, 3, 4 only
```

Which one to use:

- Chain lazy operators freely: `Where(...).OrderBy(...).Select(...)` is one pass, not three.
- Use `ToList` or `ToArray` when you will enumerate the result several times (the work is done once instead of every
  time), or when the source may change and you want a fixed copy.
- Leave a query lazy when you only need part of it, or when it should always show the current data.
- `OrderBy`, `OrderByDescending` and `Reverse` are lazy too, but they must read the whole source when enumeration starts,
  so they use memory for it.

## Operators

Each operator below is marked lazy or immediate (see above).
Examples use `Numbers = 1, 2, 3, 4, 5, 6`.

**Filtering and projection** (lazy)

| Operator | What it does |
|---|---|
| `Where(Predicate)` | Keeps the elements the predicate accepts. `Where(N mod 2 = 0)` gives 2, 4, 6. |
| `Select<R>(Selector)` | Turns each element into something else (maps it). `Select<Integer>(N * N)` gives 1, 4, 9 ... |
| `SelectMany<R>(Selector)` | Turns each element into a sequence and flattens them into one: teams into members. |
| `Zip<B, R>(Other, Combine)` | Pairs the elements of two sequences one by one; stops at the shorter. |

**Partitioning** (lazy)

| Operator | What it does |
|---|---|
| `Take(N)` | The first N elements. |
| `Skip(N)` | Everything after the first N elements. |
| `TakeWhile(Predicate)` | Elements from the start, until the predicate first fails. |
| `SkipWhile(Predicate)` | Drops elements from the start until the predicate first fails, then keeps the rest. |

**Ordering and sets** (lazy)

| Operator | What it does |
|---|---|
| `OrderBy<K>(KeySelector)` | Sorts ascending by a key. The sort is stable: equal keys keep their order. Buffers the sequence when enumeration starts. |
| `OrderByDescending<K>(KeySelector)` | The same, descending. |
| `Reverse` | The elements in opposite order. |
| `Distinct` | Each element once; the first occurrence wins. |
| `Concat(Other)` | This sequence followed by the other. Duplicates stay. |
| `Union(Other)` | Concat without duplicates. |
| `Intersect(Other)` | The elements that are in both, each once. |
| `Except(Other)` | The elements of this sequence that are not in the other, each once. |

**Single elements** (immediate)

| Operator | What it does |
|---|---|
| `First` / `First(Predicate)` | The first element (that matches). Raises `EInvalidOpException` if there is none. |
| `FirstOrDefault` / `FirstOrDefault(Predicate)` | The same, but gives `Default(T)` (0, `''`, `nil`) instead of raising. |
| `Last` / `Last(Predicate)` | The last element (that matches). Raises if there is none. |
| `LastOrDefault` / `LastOrDefault(Predicate)` | The same, but gives `Default(T)` instead of raising. |
| `Single` | The only element. Raises if the sequence is empty or has more than one. |
| `ElementAt(Index)` | The element at a zero-based position. Raises if the index is out of range. |

**Questions and counting** (immediate)

| Operator | What it does |
|---|---|
| `Any` / `Any(Predicate)` | True if there is any element (that matches). Stops at the first. |
| `All(Predicate)` | True if every element matches. True for an empty sequence. |
| `Contains(Value)` | True if the value is in the sequence (default equality). |
| `Count` / `Count(Predicate)` | The number of elements (that match). |

**Numbers** (immediate; `Sum` and `Average` work on integer and floating point types)

| Operator | What it does |
|---|---|
| `Sum` / `Sum<R>(Selector)` | The total of the elements, or of the selected values. |
| `Average` / `Average<R>(Selector)` | The mean as a `Double`. Raises on an empty sequence. |
| `Min` / `Min<R>(Selector)` | The smallest element or selected value (default comparer). Raises on an empty sequence. |
| `Max` / `Max<R>(Selector)` | The largest. Raises on an empty sequence. |
| `Aggregate<A>(Seed, Func)` | Folds the sequence into one value: starts with the seed and applies `Func(Result, Element)` to each element. `Sum`, a joined string and a maximum are all aggregates. |

**Materialising** (immediate: runs the query now and keeps the result)

| Operator | What it does |
|---|---|
| `ToList` | An `IList<T>` with the elements. A snapshot: later changes to the source do not reach it. |
| `ToArray` | A `TArray<T>`. |
| `ToHashSet` | An `ISet<T>` (duplicates dropped). |
| `ToDictionary<K>(KeySelector)` | An `IDictionary<K, T>` keyed by the selector, with the element as value. A duplicate key raises. |
| `ToDictionary<K, V>(KeySelector, ValueSelector)` | The same, with a selected value. |
| `ForEach(Action)` | Runs the action on every element. |

**Making sequences:** `Enumerable.Range(Start, Count)` gives consecutive integers, `Enumerable.Repeat<T>(Value, Count)` repeats a
value and `Enumerable.Empty<T>` gives nothing.

## Good to know

- `IList<T>.Add` also takes an open array: `Numbers.Add([7, 8, 9])`.
- A sequence enters a query with `Linq.From<T>(...)`, naming the element type: `Linq.From<TPerson>(Staff)`, and `Linq.From<string, Integer>(Stock)` for a dictionary.
- Generic operators name their result type: `Select<string>`, `Sum<Integer>`, `Average<Double>`, `Aggregate<Integer>`.
- A `TQuery<T>` converts to and from `IEnumerable<T>`, so a query can be stored in a variable, passed on and used in `for ... in`.
- `TList<T>.New` takes an open array: `TList<Integer>.New([1, 2, 3])`.

## Memory

The collections are interfaces and free themselves. Two things stay with the caller: objects stored in a list (the list
does not own them, so `LinqDemo` frees its `TPerson`s), and `Keys`/`Values` of a dictionary, which are snapshots.
Every demo sets `ReportMemoryLeaksOnShutdown := True` and waits for `ReadLn`, so the console stays open when it runs from the IDE: they all finish without a leak report.

## Build after you change a file that uses LINQ

When you change a file that uses `System.Linq` (even one blank line in a demo), run **Project > Build** (Build All) instead of
Compile. And whenever you meet one of these errors, in code that is correct, do a Build:

```
[dcc32 Error] InventoryQueries.dpr(10): E2003 Undeclared identifier: 'GetEnumeratorT'
[dcc32 Error] InventoryQueries.dpr(10): E2291 Missing implementation of interface method IEnumerable<...>.GetEnumerator
```

When Delphi's compiler reuses already compiled units, it can fail on them. This happens often, so Build is the
safe way to compile here. The error is gone after a Build; deleting the `.dcu` files next to the sources has the same
effect. `build.cmd` always compiles from source (`-B`).
