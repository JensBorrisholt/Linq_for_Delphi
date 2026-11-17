program LinqDemo;

{$APPTYPE CONSOLE}

// A tour of the collection interfaces and LINQ-style queries in standard Delphi: every list, dictionary and query result
// is an IEnumerable<T>, so the same Where/Select/OrderBy calls work on all of them once they enter a query with Linq.From.

uses
  System.SysUtils,
  Aegis.Generics.Collections in '..\Aegis.Generics.Collections.pas',
  System.Linq in '..\System.Linq.pas',
  Models in 'Models.pas';

procedure Heading(const Text: string);
begin
  WriteLn;
  WriteLn('== ' + Text + ' ==');
end;

procedure Print(const Title: string; const Items: IEnumerable<string>);
begin
  var Line := '';
  for var Item in Items do
  begin
    if Line <> '' then Line := Line + ', ';
    Line := Line + Item;
  end;
  WriteLn(Title + ': ' + Line);
end;

procedure Numbers;
begin
  Heading('Numbers');
  var Numbers := TList<Integer>.New([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

  var Evens := Linq.From<Integer>(Numbers).Where
  (
    function(N: Integer): Boolean
    begin
      Result := N mod 2 = 0;
    end
  );
  WriteLn('count of evens: ', Evens.Count);

  var SumOfSquares := Linq.From<Integer>(Numbers)
  .Select<Integer>
  (
    function(N: Integer): Integer
    begin
      Result := N * N;
    end
  )
  .Aggregate<Integer>
  (
    0,
    function(Acc, N: Integer): Integer
    begin
      Result := Acc + N;
    end
  );
  WriteLn('sum of squares: ', SumOfSquares);

  var AnyBig := Linq.From<Integer>(Numbers).Any
  (
    function(N: Integer): Boolean
    begin
      Result := N > 9;
    end
  );
  WriteLn('any > 9: ', BoolToStr(AnyBig, True));

  var AllPositive := Linq.From<Integer>(Numbers).All
  (
    function(N: Integer): Boolean
    begin
      Result := N > 0;
    end
  );
  WriteLn('all > 0: ', BoolToStr(AllPositive, True));

  var FirstBig := Linq.From<Integer>(Numbers).First
  (
    function(N: Integer): Boolean
    begin
      Result := N > 4;
    end
  );
  WriteLn('first > 4: ', FirstBig);

  WriteLn('skip 7: ', Linq.From<Integer>(Numbers).Skip(7).Count, ' left, take 3: ', Linq.From<Integer>(Numbers).Take(3).Count);
end;

procedure People;
begin
  Heading('People');
  var Staff := TList<TPerson>.New;
  Staff.Add(TPerson.Create('Anna', 34, 'Sales'));
  Staff.Add(TPerson.Create('Bjarne', 51, 'IT'));
  Staff.Add(TPerson.Create('Camilla', 28, 'IT'));
  Staff.Add(TPerson.Create('Dennis', 42, 'Sales'));
  Staff.Add(TPerson.Create('Eva', 39, 'HR'));

  var Names := Linq.From<TPerson>(Staff)
  .Where
  (
    function(P: TPerson): Boolean
    begin
      Result := P.Age >= 35;
    end
  )
  .OrderBy<string>
  (
    function(P: TPerson): string
    begin
      Result := P.Name;
    end
  )
  .Select<string>
  (
    function(P: TPerson): string
    begin
      Result := P.Name + ' (' + IntToStr(P.Age) + ')';
    end
  );
  Print('35 or older', Names);

  Names := Linq.From<TPerson>(Staff)
  .OrderByDescending<Integer>
  (
    function(P: TPerson): Integer
    begin
      Result := P.Age;
    end
  )
  .Select<string>
  (
    function(P: TPerson): string
    begin
      Result := P.Name;
    end
  );
  Print('oldest first', Names);

  var AverageAge := Linq.From<TPerson>(Staff).Average<Double>
  (
    function(P: TPerson): Double
    begin
      Result := P.Age;
    end
  );
  WriteLn('average age: ', FormatFloat('0.0', AverageAge));

  var InIT := Linq.From<TPerson>(Staff).Count
  (
    function(P: TPerson): Boolean
    begin
      Result := P.Department = 'IT';
    end
  );
  WriteLn('IT people: ', InIT);

  // The list does not own its persons: free them ourselves.
  for var P in Staff do
    P.Free;
end;

procedure Dictionaries;
begin
  Heading('Dictionary');
  var Stock := TDictionary<string, Integer>.New;
  Stock.Add('apples', 12);
  Stock.Add('pears', 0);
  Stock['plums'] := 7;

  WriteLn('items: ', Stock.Count);

  var InStock := Linq.From<string, Integer>(Stock)
  .Where
  (
    function(P: TPair<string, Integer>): Boolean
    begin
      Result := P.Value > 0;
    end
  )
  .Select<string>
  (
    function(P: TPair<string, Integer>): string
    begin
      Result := P.Key + '=' + IntToStr(P.Value);
    end
  );
  Print('in stock', InStock);

  var Total := Linq.From<Integer>(Stock.Values).Sum<Integer>
  (
    function(N: Integer): Integer
    begin
      Result := N;
    end
  );
  WriteLn('total: ', Total);
end;

procedure Ranges;
begin
  Heading('Ranges');
  Print('1..5', Enumerable.Range(1, 5).Select<string>
  (
    function(N: Integer): string
    begin
      Result := IntToStr(N);
    end
  ));

  var Words := TList<string>.New(['delta', 'alpha', 'charlie', 'bravo']);
  Print('words', Linq.From<string>(Words).OrderBy<string>
  (
    function(S: string): string
    begin
      Result := S;
    end
  ));
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  try
    Numbers;
    People;
    Dictionaries;
    Ranges;
    ReadLn;
  except
    on E: Exception do
      WriteLn(E.ClassName + ': ' + E.Message);
  end;
end.
