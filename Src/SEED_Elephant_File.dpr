program SEED_Elephant_File;

uses
  System.StartUpCopy,
  FMX.Forms,
  MainFormTabbed in 'MainFormTabbed.pas' {SeedElephantSave};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TSeedElephantSave, SeedElephantSave);
  Application.Run;
end.
