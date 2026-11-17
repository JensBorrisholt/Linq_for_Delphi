unit Models;

interface

type
  TPerson = class
  private
    FName: string;
    FAge: Integer;
    FDepartment: string;
  public
    constructor Create(const AName: string; AAge: Integer; const ADepartment: string);
    property Name: string read FName;
    property Age: Integer read FAge;
    property Department: string read FDepartment;
  end;

implementation

constructor TPerson.Create(const AName: string; AAge: Integer; const ADepartment: string);
begin
  inherited Create;
  FName := AName;
  FAge := AAge;
  FDepartment := ADepartment;
end;

end.
