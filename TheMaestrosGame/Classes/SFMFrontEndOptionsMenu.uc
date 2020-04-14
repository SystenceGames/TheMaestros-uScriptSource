class SFMFrontEndOptionsMenu extends SFMFrontEnd config(DefaultUI);

var GFxClikWidget resolutionStepper, aliasingStepper, cancelBtn, saveBtn;
var config array<string> resolutionList;
var config int resolutionIndex, aliasingIndex;

event bool WidgetInitialized(name WidgetName, name WidgetPath, GFxObject Widget)
{
	local bool bWasHandled;
	bWasHandled = false;
	switch(WidgetName)
	{
		case ('resolutionStepper'):
			resolutionStepper = GFxClikWidget(Widget);
			SetDataProvider(resolutionStepper);
			resolutionStepper.SetInt("selectedIndex", resolutionIndex);
			bWasHandled = true;
			break;
		case ('aliasingStepper'):
			aliasingStepper = GFxClikWidget(Widget);
			aliasingStepper.SetInt("selectedIndex", aliasingIndex);
			bWasHandled = true;
			break;
		case ('cancelBtn'):
			cancelBtn = GFxClikWidget(Widget);
			cancelBtn.AddEventListener('CLIK_click', CancelOptions);
			bWasHandled = true;
			break;
		case ('saveBtn'):
			saveBtn = GFxClikWidget(Widget);
			saveBtn.AddEventListener('CLIK_click', SaveOptions);
			bWasHandled = true;
			break;
		default:
			break;
	}
	return bWasHandled;
}

function SetDataProvider(GFxClikWidget Widget) {
	local byte i;
	local GFxObject DataProvider;

	DataProvider = CreateObject("scaleform.clik.data.DataProvider");

	for (i = 0; i < resolutionList.Length; i++)
		DataProvider.SetElementString(i, resolutionList[i]);

	Widget.SetObject("dataProvider", DataProvider);
}

function CancelOptions(EventData data)
{
	LoadMenu(class'SFMFrontEndMainMenu');
}

function SaveOptions(EventData data)
{
	local int ASI, RSI;
	local bool bUpdatedSettings;

	ASI = aliasingStepper.GetInt("selectedIndex");
	RSI = resolutionStepper.GetInt("selectedIndex");
	bUpdatedSettings = false;

	if (aliasingIndex != ASI) {
		aliasingIndex = ASI;
		ConsoleCommand("Scale Set MaxMultiSamples " $ aliasingStepper.GetString("selectedItem"));
		bUpdatedSettings = true;
	}

	if (resolutionIndex != RSI) {
		resolutionIndex = RSI;
		ConsoleCommand("Setres " $ resolutionStepper.GetString("selectedItem") $ "w");
		bUpdatedSettings = true;
	}

	if (bUpdatedSettings) {
		SaveConfig();
	}

	LoadMenu(class'SFMFrontEndMainMenu');
}

DefaultProperties
{
	MovieInfo=SwfMovie'ScaleformMenuGFx.SFMFrontEnd.SF_OptionsMenu'
	WidgetBindings.Add((WidgetName="resolutionStepper",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="aliasingStepper",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="cancelBtn",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="saveBtn",WidgetClass=class'GFxCLIKWidget'))
}
