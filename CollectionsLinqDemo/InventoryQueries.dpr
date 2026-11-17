program InventoryQueries;

{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  Aegis.Generics.Collections in '..\Aegis.Generics.Collections.pas',
  System.Linq in '..\System.Linq.pas';

// Query a dictionary without exposing its concrete implementation.

procedure Run;
begin
  var Stock := TDictionary<string, Integer>.New;
  Stock.Add('bolts', 12);
  Stock.Add('nuts', 0);
  Stock.Add('washers', 7);
  Stock.Add('screws', 21);

  var InStock := Linq.From<string, Integer>(Stock)
  .Where
  (
    function(P: TPair<string, Integer>): Boolean
    begin
      Result := P.Value > 0;
    end
  )
  .OrderBy<string>
  (
    function(P: TPair<string, Integer>): string
    begin
      Result := P.Key;
    end
  )
  .Select<string>
  (
    function(P: TPair<string, Integer>): string
    begin
      Result := P.Key;
    end
  );

  WriteLn('Available products:');
  for var Item in InStock do
    WriteLn('  ' + Item);

  var Total := Linq.From<Integer>(Stock.Values).Sum;
  WriteLn('Units in stock: ', Total);

  var OutOfStock := Linq.From<string, Integer>(Stock).Count
  (
    function(P: TPair<string, Integer>): Boolean
    begin
      Result := P.Value = 0;
    end
  );
  WriteLn('Products out of stock: ', OutOfStock);
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  Run;
  ReadLn;
end.
