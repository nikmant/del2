unit MainFormTabbed;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.TabControl,
  FMX.StdCtrls, FMX.Gestures, FMX.Controls.Presentation, FMX.Edit, system.IOUtils,
  Math,
  {$IFDEF ANDROID}
  Androidapi.Helpers, Androidapi.JNI.JavaTypes, Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.Net, Androidapi.JNI.OS, FMX.Platform.Android,
  {$ENDIF}
  System.Permissions, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, System.Generics.Collections,
  FMX.Layouts;

type
  TSeedElephantSave = class(TForm)
    HeaderToolBar: TToolBar;
    ToolBarLabel: TLabel;
    TabControl1: TTabControl;
    tsEncode: TTabItem;
    tsDecode: TTabItem;
    GestureManager1: TGestureManager;
    Label1: TLabel;
    EditFileName1: TEdit;
    BSave: TButton;
    MemoSeed1: TMemo;
    Label2: TLabel;
    Label3: TLabel;
    MemoPhrase1: TMemo;
    MemoDictionary: TMemo;
    saveToProgram1: TRadioButton;
    saveToDownload1: TRadioButton;
    Label4: TLabel;
    Label5: TLabel;
    MemoPhrase2: TMemo;
    Label6: TLabel;
    EditFileName2: TEdit;
    Label7: TLabel;
    saveToProgram2: TRadioButton;
    saveToDownload2: TRadioButton;
    LabelRes2: TLabel;
    Label9: TLabel;
    MemoSeed2: TMemo;
    Label8: TLabel;
    TimerDecode: TTimer;
    Label10: TLabel;
    LabelPhrase1: TLabel;
    LabelRes1: TLabel;
    tsAbout: TTabItem;
    Memo1: TMemo;
    Panel1: TPanel;
    Edit1: TEdit;
    Edit2: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormGesture(Sender: TObject; const EventInfo: TGestureEventInfo;
      var Handled: Boolean);
    procedure BSaveClick(Sender: TObject);
    procedure MemoSeed1Change(Sender: TObject);
    procedure SomethingOnDecodePageChange(Sender: TObject);
    procedure TimerDecodeTimer(Sender: TObject);
  private
    { Private declarations }
    procedure TryLoadAndDecode;
  public
    { Public declarations }
  end;

var
  SeedElephantSave: TSeedElephantSave;
  FPermissionWrite: string;
  FPermissionRead: string;
  seed1_words_count, seed2_words_count: integer;
  seed_Dic: TDictionary<string, integer>;
  seed1_SEED: array [0..23] of string;
  seed1_InFile, seed2_InFile: array [0..2047] of string;
  seed1_Num: Array of integer;
  hasCyrillic, hasLatin, isEventsON: Boolean;

implementation

{$R *.fmx}

const
  WRITE_EXTERNAL_STORAGE_REQUEST_CODE = 100;

procedure TSeedElephantSave.FormCreate(Sender: TObject);
var n: integer;
s:string;
begin
  MemoDictionary.Visible := False;
  {$IFDEF ANDROID}
  FPermissionWrite := JStringToString(TJManifest_permission.JavaClass.WRITE_EXTERNAL_STORAGE); //Значение на запись
  FPermissionRead := JStringToString(TJManifest_permission.JavaClass.READ_EXTERNAL_STORAGE); //Значение на чтение
  {$ENDIF}
  seed_Dic := TDictionary<string, integer>.Create;
  for n:=0 to MemoDictionary.Lines.Count-1 do
  begin
    s := MemoDictionary.Lines.Strings[n];
    seed_Dic.Add(s, n);
  end;

  isEventsON := False;

  // Галочка по-умолчанию
  {$IFDEF ANDROID}
  saveToDownload1.IsChecked := True;
  {$ELSE}
  saveToProgram1.IsChecked := True;
  {$ENDIF}

  {$IFDEF ANDROID}
  saveToDownload2.IsChecked := True;
  {$ELSE}
  HeaderToolBar.Visible := False;
  saveToProgram2.IsChecked := True;
  {$ENDIF}

  isEventsON := True;

end;

procedure TSeedElephantSave.MemoSeed1Change(Sender: TObject);
begin
  LabelRes1.text := '';
  LabelRes1.TextSettings.FontColor := 0;
  EditFileName2.Text := EditFileName1.Text;
end;

procedure TSeedElephantSave.FormGesture(Sender: TObject;
  const EventInfo: TGestureEventInfo; var Handled: Boolean);
begin
{$IFDEF ANDROID}
  case EventInfo.GestureID of
    sgiLeft:
    begin
      if TabControl1.ActiveTab <> TabControl1.Tabs[TabControl1.TabCount-1] then
        TabControl1.ActiveTab := TabControl1.Tabs[TabControl1.TabIndex+1];
      Handled := True;
    end;
    sgiRight:
    begin
      if TabControl1.ActiveTab <> TabControl1.Tabs[0] then
        TabControl1.ActiveTab := TabControl1.Tabs[TabControl1.TabIndex-1];
      Handled := True;
    end;
  end;
{$ENDIF}
end;

function ArrCheckHaveDoubles(const arr: TArray<Integer>): boolean;
var n,m: integer;
begin
  result := False;
  for n:=0 to Length(arr)-2 do
    for m:=n+1 to Length(arr)-1 do
      if arr[n]=arr[m] then
        result:=true;
end;

function PrepareSeed(const input: string): string;
var
  i: Integer;
begin
  Result := input;

  // Приведение всех символов к нижнему регистру
  Result := AnsiLowerCase(Result);

  // Замена символов перевода строки, табуляции и иных спец-символов на пробелы
  for i := 1 to Length(Result) do
  begin
    if NOT(Result[i] in ['a'..'z', ' ']) then
      Result[i] := ' ';
  end;

  // Замена множественных пробелов на одиночные пробелы
  i := 1;
  while i < Length(Result) do
  begin
    if (Result[i] = ' ') and (Result[i + 1] = ' ') then
      Delete(Result, i, 1)
    else
      Inc(i);
  end;
end;

function PreparePhrase(const input: string): string;
var i,d,o1,o2,o3,o4: integer;
begin
  Result := input;

  // Приведение всех символов к нижнему регистру
  Result := AnsiLowerCase(Result);

  // Замена Ё на Е, так как номер символа "Ё" на 2 больше чем "Я"
  for i := 1 to Length(Result) do
  begin
    if (Result[i]='ё') then
      Result[i] := 'е';
  end;

  // Замена символов перевода строки, табуляции и иных спец-символов на пробелы
  o1 := ord('a');
  o2 := ord('z');
  o3 := ord(AnsiLowerCase('а')[1]);
  o4 := ord(AnsiLowerCase('я')[1]);
  for i := 1 to Length(Result) do
  begin
    d := ord(Result[i]);
    if NOT(  ((d>=o1)and(d<=o2)) or ((d>=o3)and(d<=o4))  )
    then
      Result[i] := ' ';
  end;

  // Удаление пробелов
  i := 1;
  while i <= Length(Result) do
  begin
    if (Result[i] = ' ') then
      Delete(Result, i, 1)
    else
      Inc(i);
  end;

  hasCyrillic := False;
  hasLatin := False;

  for i := 1 to Length(Result) do
  begin
    d := ord(Result[i]);
    if ((d>=o1)and(d<=o2)) then
      hasLatin := True;
    if ((d>=o3)and(d<=o4)) then
      hasCyrillic := True;
  end;

end;

procedure GetWordNumbers(const input: string);
var
  words: TStringList;
  word: string;
  i: Integer;
begin
  words := TStringList.Create;
  try
    // Разбиваем строку на отдельные слова
    words.Delimiter := ' ';
    words.DelimitedText := input;

    // Создаем массив номеров слов
    SetLength(seed1_Num, words.Count);

    // Заполняем массив номерами слов
    seed1_words_count := words.Count;
    SetLength(seed1_Num, seed1_words_count);
    for i := 0 to words.Count - 1 do
    begin
      word := words[i];
      seed1_SEED[i] := word;
      // Проверяем, содержится ли слово в словаре
      if seed_Dic.ContainsKey(word) then
        seed1_Num[i] := seed_Dic[word]
      else
        seed1_Num[i] := -1; // Если слова нет в словаре, присваиваем -1
    end;
  finally
    words.Free;
  end;
end;

function XbaseToYbase(const arr: TArray<Integer>; Xbase: Integer; Ybase: Integer): TArray<Integer>;
var i,j,carry: Integer;
res: TArray<Integer>;
begin
  SetLength(res, 1);
  res[0] := 0;
  for i := 0 to High(arr) do
  begin
    carry := 0;
    for j := 0 to High(res) do
    begin
      res[j] := res[j] * Xbase + carry;
      carry := res[j] div Ybase;
      res[j] := res[j] mod Ybase;
    end;
    while carry > 0 do
    begin
      SetLength(res, Length(res) + 1);
      res[High(res)] := carry mod Ybase;
      carry := carry div Ybase;
    end;
    carry := arr[i];
    for j := 0 to High(res) do
    begin
      res[j] := res[j] + carry;
      carry := res[j] div Ybase;
      res[j] := res[j] mod Ybase;
    end;
    while carry > 0 do
    begin
      SetLength(res, Length(res) + 1);
      res[High(res)] := carry mod Ybase;
      carry := carry div Ybase;
    end;
  end;
  // revers
  SetLength(result, Length(res));
  for i:=Length(res)-1 downto 0 do
    result[Length(res)-i-1] := res[i];
end;

procedure RandomizeStringList(var A: TStringList);
var n, Q, CountTotal: integer;
s: string;
begin
  Randomize;
  CountTotal := A.Count;
  for n:=0 to CountTotal-1 do
  begin
    Q := n+random(CountTotal-n);
    s := A[Q];
    A.Delete(Q);
    A.Insert(n,s);
  end;
end;

procedure TSeedElephantSave.BSaveClick(Sender: TObject);
var SL: TStringList;
n, ind_is_file, i_next: integer;
filename: string;
seed1, phrase1: string;
is_seed1_ok: boolean;
firstChar: char;
chars_count, ord1, ord2: integer;
phrase1_need_long: integer;
a,b: double;
abc, x2048: TArray<integer>;
other_words: TStringList;
file_string_list: TStringList;
begin

  // Проверяю, есть ли права на запись файлов
  if NOT PermissionsService.IsPermissionGranted(FPermissionWrite) then
    PermissionsService.RequestPermissions([FPermissionWrite, FPermissionRead], nil);
  if NOT PermissionsService.IsPermissionGranted(FPermissionWrite) then
    exit;

  LabelRes1.TextSettings.FontColor := 255;

  if EditFileName1.Text='' then
  begin
    LabelRes1.text := 'Filename cannot be empty.';
    exit;
  end;

  // Считываю кодируемую SEED фразу
  seed1 := MemoSeed1.Lines.Text;
  // и преобразую её выбрасывая лишние символы,
  seed1 := PrepareSeed(seed1);

  // Узнаю количество слов в SEED
  GetWordNumbers(seed1);

  // Если количество слов не стандартное, то ошибка
  if not(seed1_words_count in [12,15,18,21,24]) then
  begin
    LabelRes1.text := 'SEED length allowed only 12,15,18,21,24 words';
    exit;
  end;

  // Пытаюсь распознать все слова,
  // и найти их номера в словаре
  is_seed1_ok := True;
  for n:=0 to seed1_words_count-1 do
  begin
    if seed1_Num[n]=-1 then
    begin
      LabelRes1.text := 'Unrecognized word in SEED. Word number '+IntToStr(n+1);
      is_seed1_ok := False;
      exit;
    end;
  end;

  // Считываю фразу для кодирвания
  phrase1 := MemoPhrase1.Lines.Text;
  phrase1 := PreparePhrase(phrase1);

  // Проверяю, что фраза для кодирования задана только на одном языке
  if (phrase1='') then
  begin
    LabelRes1.text := 'Enter Phrase';
    exit;
  end;

  // Проверяю, что фраза для кодирования задана только на одном языке
  if NOT(hasCyrillic XOR hasLatin) then
  begin
    LabelRes1.text := 'You can use only characters of either Latin or Cyrillic';
    exit;
  end;

  // По умолчанию 26 символов, но если русский, то ...
  chars_count := 26;
  firstChar := AnsiLowerCase('a')[1];
  if hasCyrillic then
  begin
    firstChar := AnsiLowerCase('а')[1];
    chars_count := 32;
  end;

  // Определяю сколько букв нужно для фразы на этом языке
  a := seed1_words_count*11;
  b := LogN(2, chars_count);
  phrase1_need_long := trunc(a/b)+1;

  // Если букв фразы не достаточно, то ошибка
  if (Length(phrase1)<phrase1_need_long) then
  begin
    LabelRes1.text := 'Add '+inttostr(phrase1_need_long-Length(phrase1))+' letters to the phrase. Need total '+inttostr(phrase1_need_long)+' letters';
    exit;
  end;

  // Составляю массив из чисел, соответствующих индексам букв в выбранном алфавите (индекс "а" равен 0)
  SetLength(abc, Length(phrase1));
  for n:=0 to Length(phrase1)-1 do
  begin
    ord1 := ord(AnsiLowerCase(phrase1[n+1])[1]);
    ord2 := ord(AnsiLowerCase(firstChar)[1]);
    abc[n] := ord1 - ord2;
    if (abc[n]<0) or (abc[n]>chars_count-1) then
    begin
      LabelRes1.text := 'Error get code for letter number '+inttostr(n)+'. Char "'+phrase1[n]+'".';
      exit;
    end;
  end;

  // Составляю массив из чисел, с номерами мест, куда нужно будет расположить закодированные слова SEED
  x2048 := XbaseToYbase(abc, chars_count, 2048);

  // Проверяю, что нет повторяющихся индексов слов в 2048-ичной системе исчисления
  if ArrCheckHaveDoubles(x2048) then
  begin
    LabelRes1.text := '12% phrases are not suitable for 24-SEED coding. 3% - for 12-SEED. This is one of them. Add or change a letter or word in a phrase.';
    exit;
  end;

  // Очищаю массив содержащий слова для записи в файл в нужном порядке
  for n:=0 to 2047 do
    seed1_InFile[n]:='';

  // Создаю мэп, содержащий только 12-24 нужных мне SEED слова, и их индексы в зашифрованном файле
  for n:=0 to seed1_words_count-1 do
  begin
    ind_is_file := x2048[n];
    seed1_InFile[ind_is_file] := seed1_SEED[n];
  end;

  // Составляю список оставшихся 2000 слов, которые не были использованы в SEED
  other_words := TStringList.Create;
  for n:=0 to MemoDictionary.Lines.Count-1 do
  begin
    if NOT(pos(' '+MemoDictionary.Lines.Strings[n]+' ', ' '+seed1+' ')>0) then
      other_words.Add(MemoDictionary.Lines.Strings[n]);
  end;

  // Перемешиваю список оставшихся слов
  RandomizeStringList(other_words);

  // Заполняю пустые места массива неиспользуемыми словами
  i_next := 0;
  for n:=0 to 2047 do
  begin
    if seed1_InFile[n]='' then
    begin
      seed1_InFile[n] :=
//      UPPERCASE(
      other_words[i_next]
//      )
      ;
      i_next := i_next + 1;
    end;
  end;

  // Формирую данные в виде StringList, чтобы удобнее было записывать в файл
  file_string_list := TStringList.Create;
  for n:=0 to 2047 do
    file_string_list.Add( seed1_InFile[n] );

  // Полное название файла для сохранения
  if saveToDownload1.IsChecked
    then filename := TPath.GetDownloadsPath
    else filename := ExtractFileDir(ParamStr(0));
  {$IFDEF ANDROID}
  if saveToDownload1.IsChecked
    then filename := TPath.GetSharedDownloadsPath
    else filename := TPath.GetDocumentsPath;
  {$ENDIF}
  filename := filename + PathDelim + EditFileName1.Text + '.seed';

  // Сохраняю в файл
  // if FileExists(filename) then
  try
    DeleteFile(filename);
  except
  end;
  file_string_list.SaveToFile(filename);

  // Вывожу сообщение, что созранение успешно завершено
  LabelRes1.text := 'Ready. The file has been saved:'+#13+filename+#13+#13+'You can safely store this file in a public place on the Internet.';
  LabelRes1.TextSettings.FontColor := 255*256;

end;

procedure TSeedElephantSave.SomethingOnDecodePageChange(Sender: TObject);
begin
  LabelRes2.text := '';
  MemoSeed2.Lines.Clear;
  if isEventsON then
  begin
    TimerDecode.Enabled := False;
    TimerDecode.Enabled := True;
    EditFileName1.Text := EditFileName2.Text;
  end;
end;

procedure TSeedElephantSave.TimerDecodeTimer(Sender: TObject);
begin
  TimerDecode.Enabled := False;
  TryLoadAndDecode;
end;

procedure TSeedElephantSave.TryLoadAndDecode;
var SL: TStringList;
n, ind_is_file, i_next: integer;
filename: string;
seed2, phrase2: string;
is_seed1_ok: boolean;
firstChar: char;
chars_count, ord1, ord2: integer;
phrase2_need_long: integer;
a,b: double;
abc, x2048: TArray<integer>;
other_words: TStringList;
file_string_list: TStringList;
word, s_res: string;
begin

  // Вывожу на всякий случая сообщение о неопознанной ошибке
  LabelRes2.TextSettings.FontColor := 255*256;
  LabelRes2.text := 'Error. Unidentified.';

  // Проверяю, есть ли права на запись файлов
  if NOT PermissionsService.IsPermissionGranted(FPermissionRead) then
    PermissionsService.RequestPermissions([FPermissionWrite, FPermissionRead], nil);
  if NOT PermissionsService.IsPermissionGranted(FPermissionRead) then
    exit;

  // Полное название файла для сохранения
  if saveToDownload2.IsChecked
    then filename := TPath.GetDownloadsPath
    else filename := ExtractFileDir(ParamStr(0));
  {$IFDEF ANDROID}
  if saveToDownload1.IsChecked
    then filename := TPath.GetSharedDownloadsPath
    else filename := TPath.GetDocumentsPath;
  {$ENDIF}
  filename := filename + PathDelim + EditFileName1.Text + '.seed';

  // Считываю файл
  file_string_list := TStringList.Create;
  if FileExists(filename) then
  begin
    file_string_list.LoadFromFile(filename);
  end
  else
  begin
    LabelRes2.text := 'Error. File not found. '+filename;
    exit;
  end;

  // Узнаю чколько строк в файле
  seed2_words_count := file_string_list.Count;
  if (seed2_words_count<>2048) then
  begin
    LabelRes2.text := 'Error. File must contain 2048 words in 2048 lines. In real '+inttostr(seed2_words_count)+' lines.';
    exit;
  end;

  // Заполняем массив номерами слов
  for n:=0 to seed2_words_count-1 do
  begin
    word := file_string_list.Strings[n];
    // Проверяем, содержится ли слово в словаре
    if seed_Dic.ContainsKey(word) then
    begin
      seed2_InFile[n] := word;
    end
    else
    begin
      LabelRes2.text := 'Error. Word not found in dictionary: '+#13+word;
      exit;
    end;
  end;


  // Считываю фразу для кодирвания
  phrase2 := MemoPhrase2.Lines.Text;
  phrase2 := PreparePhrase(phrase2);

  // Проверяю, что фраза для кодирования задана только на одном языке
  if (phrase2='') then
  begin
    LabelRes2.text := 'Enter Phrase';
    exit;
  end;

  // Проверяю, что фраза для кодирования задана только на одном языке
  if NOT(hasCyrillic XOR hasLatin) then
  begin
    LabelRes2.text := 'You can use only characters of either Latin or Cyrillic';
    exit;
  end;

  // По умолчанию 26 символов, но если русский, то ...
  chars_count := 26;
  firstChar := AnsiLowerCase('a')[1];
  if hasCyrillic then
  begin
    firstChar := AnsiLowerCase('а')[1];
    chars_count := 32;
  end;

  // Составляю массив из чисел, соответствующих индексам букв в выбранном алфавите (индекс "а" равен 0)
  SetLength(abc, Length(phrase2));
  for n:=0 to Length(phrase2)-1 do
  begin
    ord1 := ord(AnsiLowerCase(phrase2[n+1])[1]);
    ord2 := ord(AnsiLowerCase(firstChar)[1]);
    abc[n] := ord1 - ord2;
    if (abc[n]<0) or (abc[n]>chars_count-1) then
    begin
      LabelRes2.text := 'Error get code for letter number '+inttostr(n)+'. Char "'+phrase2[n]+'".';
      exit;
    end;
  end;

  // Составляю массив из чисел, с номерами мест, ИЗ КОТОРЫХ нужно будет СЧИТАТЬ закодированные слова SEED
  x2048 := XbaseToYbase(abc, chars_count, 2048);

  // Нахожу слова соответствующие выбранным номерам
  s_res := '';
  for n:=0 to Length(x2048)-1 do
  begin
    if (s_res<>'') then s_res:=s_res+' ';
    s_res := s_res + seed2_InFile[x2048[n]];
  end;

  // Вывожу слова соответствующие выбранным номерам
  LabelRes2.Text := 'Decoding completed successfully';
  MemoSeed2.Lines.Text := s_res;

end;

end.
