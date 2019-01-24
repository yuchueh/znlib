{*******************************************************************************
  作者: dmzn@163.com 2017-03-27
  描述: 统一管理各种管理器的全局变量
*******************************************************************************}
unit UManagerGroup;

{$I LibFun.Inc}
interface

uses
  System.Rtti, System.SysUtils, UBaseObject, UObjectPool, UMemDataPool,
  {$IFDEF EnableLogManager}UMgrLog,{$ENDIF}
  {$IFDEF EnableThreadPool}UThreadPool,{$ENDIF}
  {$IFDEF EnableChannelManager}UMgrChannel,{$ENDIF}
  ULibFun;

type
  PManagerGroup = ^TManagerGroup;
  TManagerGroup = record
  public
    const 
      sAllManager = 'ALLManager';
      {*常量定义*}
    type
      TItem = record
        FClass   : TClass;
        FManager : TManagerBase;
      end;
      {*实例定义*}
    var
      FManagers: array of TItem;
      {*实例列表*}
  public
    FObjectPool: TObjectPoolManager;
    //对象缓冲池
    FMemDataManager: TMemDataManager;
    //内存管理器
    FSerialIDManager: TSerialIDManager;
    //编号管理器
    FObjectManager: TCommonObjectManager;
    //对象管理器
    {$IFDEF EnableThreadPool}FThreadPool: TThreadPoolManager;{$ENDIF}
    //线程管理器
    {$IFDEF EnableChannelManager}FChannelManager: TChannelManager;{$ENDIF}
    //RemObjects通道管理器
    {$IFDEF EnableLogManager}FLogManager: TLogManager;{$ENDIF}
    //日志管理器
  public
    procedure RegistAll(const nReg: Boolean);
    //注册所有
    procedure CheckSupport(const nCallClass,nManagerName: string;
      const nManager: TObject); overload;
    procedure CheckSupport(const nCallClass: string;
      const nManagers: TStringHelper.TStringArray); overload;    
    //验证所需管理器是否正常
  end;

var
  gMG: TManagerGroup;
  //全局使用
  
implementation

//Date: 2017-03-27
//Parm: 是否注册
//Desc: 扫描Group中所有Manager,调用Manager的注册方法.
procedure TManagerGroup.RegistAll(const nReg: Boolean);
var nCtx: TRttiContext;
    nType: TRttiType;
    nRF: TRttiField;
    nMethod: TRttiMethod;
    nInstance: TRttiInstanceType;
begin
  nCtx := TRttiContext.Create;
  try
    nType := nCtx.GetType(TypeInfo(TManagerGroup));
    if not nReg then
    begin
      for nRF in nType.GetFields do
      begin
        if nRF.FieldType.TypeKind <> tkClass then Continue;
        nInstance := nRF.FieldType.AsInstance;
        nMethod := nInstance.GetMethod('RunBeforUnregistAllManager');

        if Assigned(nMethod) then
          nMethod.Invoke(nRF.GetValue(@gMG).AsObject, []);
        //卸载前执行
      end;
    end;

    for nRF in nType.GetFields do
    begin
      if nRF.FieldType.TypeKind <> tkClass then Continue;
      nInstance := nRF.FieldType.AsInstance;
      nMethod := nInstance.GetMethod('RegistMe');

      if Assigned(nMethod) then
        nMethod.Invoke(nInstance.MetaclassType, [TValue.From(nReg)]);
      //call function
    end;

    if nReg then
    begin
      for nRF in nType.GetFields do
      begin
        if nRF.FieldType.TypeKind <> tkClass then Continue;
        nInstance := nRF.FieldType.AsInstance;
        nMethod := nInstance.GetMethod('RunAfterRegistAllManager');

        if Assigned(nMethod) then
          nMethod.Invoke(nRF.GetValue(@gMG).AsObject, []);
        //注册后执行
      end;
    end;
  finally
    nCtx.Free;
  end;
end;

//Date: 2017-04-18
//Parm: 调用类;变量名;管理器变量
//Desc: 当nCallClass需要nManager支持,但nManager为nil,抛出异常.
procedure TManagerGroup.CheckSupport(const nCallClass,nManagerName: string;
  const nManager: TObject);
var nStr: string;
begin
  if not Assigned(nManager) then
  begin
    nStr := '%s Needs TManagerGroup.%s(nil) Support.';
    raise Exception.Create(Format(nStr, [nCallClass, nManagerName]));
  end;
end;

//Date: 2017-04-17
//Parm: 调用类;所需管理器变量名
//Desc: 检查nCallClsss所需的nManagers是否存在
procedure TManagerGroup.CheckSupport(const nCallClass: string;
  const nManagers: TStringHelper.TStringArray);
var nStr,nBase: string;
    nBool: Boolean;
    nCtx: TRttiContext;
    nType: TRttiType;
    nRF: TRttiField;    
begin
  nCtx := TRttiContext.Create;
  try
    nType := nCtx.GetType(TypeInfo(TManagerGroup));
    for nBase in nManagers do
    begin
      nBool := False;
      //init flag
      
      for nRF in nType.GetFields do
      begin
        nBool := (nBase = nRF.FieldType.Name) or (nBase = sAllManager);
        if not nBool then Continue;
        
        if nRF.FieldType.TypeKind = tkClass then
        begin
          CheckSupport(nCallClass, nRF.Name, nRF.GetValue(@gMG).AsObject);
          if nBase <> sAllManager then
            Break; 
          //match done  
        end else

        if nBase <> sAllManager then        
        begin
          nStr := '%s: Manager "%s" Is Not Valid Class.';
          raise Exception.Create(Format(nStr, [nCallClass, nBase]));
        end;  
      end;

      if not nBool then
      begin
        nStr := '%s: Manager "%s" Is Not Exists.';
        raise Exception.Create(Format(nStr, [nCallClass, nBase]));
      end; //not exits
    end;
  finally
    nCtx.Free;
  end;    
end;

initialization
  FillChar(gMG, SizeOf(TManagerGroup), #0);
  gMG.RegistAll(True);
finalization
  gMG.RegistAll(False);
end.
