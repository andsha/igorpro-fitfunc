// 		XPS quick fit dialog V 2.3.7
//		20 - Feb - 2013
// 		version 2.2 issued 05 Nov 2011
//		Developed by Andrey Shavorskiy, Georg Held
//
//		2011 - 12 - 10	Modified XPS_1GLAs fit function. Now it takes structure as a parameter. No wave referencing inside function. Fit is much faster
//							Modified DoFIt and DoMultiFit functions. In multifit function multithreading is implemented
//							added Background variable in the fit dialog

#pragma rtGlobal=1		// Use modern global access method.

Structure stFitFuncStruct // structure to pass to fit function
	wave w
	variable x
	WAVE wCurLinks
	WAVE wCurLinkVs
	wave wMinC
	wave wMaxC
	WAVE /T CursorNames 
	variable nNumOfPeaks	
	wave wGLAsArea
endstructure

function XPS_NEW_fit_dialog()
end

//Menu "XPS"
				

		
		//"Get peak info", GetGFitInfo()
		//"Fit waves from top graph", DoMultiFit() //FitMultiWavesPanel (0)
		//"Normalize by area", NormByArea()		
	

//end
//__________________________________________________________________
function CreateGlobals()

	SVAR /Z sXPSDialogVersion = root:XPS_Fit_dialog:g_sXPSDialogVersion
	SVAR /Z sXPSUpdVer = root:XPS_Fit_dialog:g_sXPSUpdVer
	
	String sLatestVersion = "2.3.7"
	String sLatestUpdVer = "1.0"
	
	if ((SVAR_Exists(sXPSUpdVer) && !stringmatch(sXPSUpdVer,sLatestUpdVer)))
		DoAlert 0, "User should update XPSFit.ipf procedure. Close All Igor Pro experiments and copy the file from \"User Procedures\" to \"Igor Procedures\" folder."
	endif

	if (!SVAR_Exists(sXPSDialogVersion) || (SVAR_Exists(sXPSDialogVersion) && !stringmatch(sXPSDialogVersion,sLatestVersion)))
		print "Update to version", sLatestVersion
		XPS_FitD_Migrate()
	else
		if (DataFolderExists("XPS_Fit_dialog"))
			return 0
		endif
	endif 
		

	SetDataFolder root:
	NewDataFolder /O XPS_Fit_dialog 
	SetDataFolder root:XPS_Fit_dialog

	Variable /G n_RegWidth = 250 // region width
	Variable /G n_RegHeigth = 135 // region heigth
	Variable /G n_InterCtrlDis = 5 // distance between buttons
	Variable /G n_NumRegsRow = 3 // number of regions in a row
	Variable /G nTabHeight = 25

	Variable /G n_MaxRegs = 12
	Variable /G n_NumOfRegs // actual number of regions
	Variable /G n_NumOfPeaks
	String /G s_PopUpValue = ""

	Make /T /O /N = (n_MaxRegs) CursorColours 
	Wave /T CursorColours = CursorColours 

	CursorColours [0] = "Red"
	CursorColours[1] = "Black"
	CursorColours[2] = "Blue"
	CursorColours[3] = "Green"
	CursorColours[4] = "Orange"
	CursorColours[5] = "Magenta"
	CursorColours[6] = "Purple"
	CursorColours[7] = "Grey"
	CursorColours[8] = "Brown"
	CursorColours[9] = "Yellow"
	CursorColours[10] = "Light Blue"
	CursorColours[11] = "Light Green"

	Make /O /N = (n_MaxRegs, 3) PeakColours
	Wave PeakColours = PeakColours
	//Red
	PeakColours[0][0] = 65535 //Red
	PeakColours[0][1] = 0 // Green
	PeakColours[0][2] = 0 // Blue
	//Black
	PeakColours[1][0] = 0 //Red
	PeakColours[1][1] = 0 // Green
	PeakColours[1][2] = 0 // Blue
	//Blue
	PeakColours[2][0] = 0 //Red
	PeakColours[2][1] = 0 // Green
	PeakColours[2][2] = 65535 // Blue
	//Green
	PeakColours[3][0] = 0 //Red
	PeakColours[3][1] = 38550 // Green
	PeakColours[3][2] = 0 // Blue
	//Orange
	PeakColours[4][0] = 65535 //Red
	PeakColours[4][1] = 43690 // Green
	PeakColours[4][2] = 0 // Blue
	//Magenta
	PeakColours[5][0] = 55552 //Red
	PeakColours[5][1] = 9216 // Green
	PeakColours[5][2] = 59392 // Blue
	//Purple
	PeakColours[6][0] = 27648 //Red
	PeakColours[6][1] = 15360 // Green
	PeakColours[6][2] = 48384 // Blue
	//Green
	PeakColours[7][0] = 38550 //Red
	PeakColours[7][1] = 38550 // Green
	PeakColours[7][2] = 38550 // Blue
	//Brown
	PeakColours[8][0] = 21248 //Red
	PeakColours[8][1] = 6912 // Green
	PeakColours[8][2] = 0 // Blue
	//Yellow
	PeakColours[9][0] = 65535 //Red
	PeakColours[9][1] = 65535 // Green
	PeakColours[9][2] = 0 // Blue
	//Light Blue
	PeakColours[10][0] = 0 //Red
	PeakColours[10][1] = 65535 // Green
	PeakColours[10][2] = 65535 // Blue
	// Light Green
	PeakColours[11][0] = 0 //Red
	PeakColours[11][1] = 65535 // Green
	PeakColours[11][2] = 0 // Blue

	Make /T /O /N = (n_MaxRegs) CursorNames 
	Wave /T CursorNames = CursorNames 
	
	CursorNames[0] = "A"
	CursorNames[1] = "B"
	CursorNames[2] = "C"
	CursorNames[3] = "D"
	CursorNames[4] = "E"
	CursorNames[5] = "F"
	CursorNames[6] = "G"
	CursorNames[7] = "H"
	CursorNames[8] = "I"
	CursorNames[9] = "J"
	CursorNames[10] = "K"
	CursorNames[11] = "L"
	String /G XPSWindowName="XPS_Fit_Panel"
	String /G g_CurLinkVs
	String /G g_CurLinks
	String /G g_CurHold
	String /G g_CurUse
	String /G g_CurMinC
	String /G g_CurMaxC
	String /G g_sXPSDialogVersion = sLatestVersion
	String /G g_sXPSUpdVer = sLatestUpdVer

	SetDataFolder root:
	
	if (!WaveExists(wCoef2DWave))
		Make /O /N= (n_MaxRegs * 5 + 1,1,7) wCoef2DWave
		Make /T /O /N=1 wCoefNamesWave
	else
		Redimension /N=(DimSize(wCoef2DWave,0), DimSize(wCoef2DWave,1),7) wCoef2DWave
	endif
	
	SetDataFolder root:XPS_Fit_dialog:
	
	//*****  MutliFit dialog globals  ******
	
	Variable /G g_lastColor = 2
	Variable /G g_SelCol = -1

	variable  /G g_MUTLIFIT_deltaInt = 0.05 // proportional to total int 
	variable /G g_MUTLIFIT_deltaPos = 0.05 // eV
	variable /G g_MUTLIFIT_deltaFwhm = 0.01// eV
	variable /G g_MUTLIFIT_deltaAssym = 0.05 // abs value
	variable /G g_MUTLIFIT_deltaMix = 0.05 // abs value
	variable /G g_MULTIFIT_nMaxNumStep = 10 // maximum number of itirations in Levenberg?Marquardt algorithm
	
	
	//********* GLAs area 2D wave ***********
	Load2DAreaWave()
	
	
	
	
	SetDataFolder root:
end
//___________________________________________________________
 
 // Creates panel for wave fitting
 
 function FitPanel(num)
	variable num
	
	CreateGlobals()
	
	NVAR /Z n_NumOfRegs = root:XPS_Fit_dialog:n_NumOfRegs
	NVAR /Z  n_NumRegsRow = root:XPS_Fit_dialog:n_NumRegsRow

	//Prompt cnt, "Number of regions", popup "3;6;9;12"
	if (!num)
		num = 3
		//DoPrompt "Number of regions", cnt
		//if (v_flag == 1)
		//	return 0
		//endif
	//else
		
	endif
		
	Variable cnt = num / n_NumRegsRow
		
	//cnt  = num
	n_NumOfRegs = n_NumRegsRow * cnt
	SVAR sPopUpValue = root:XPS_fit_dialog:s_PopUpValue
	sPopUpValue = "\""
	variable i = 0
	for (i = 0; i < n_NumOfRegs; i += 1)
		sPopUpValue += num2str(i + 1) + ";"
	endfor
	sPopUpValue += "\""

	SVAR /Z XPSWindowName = root:XPS_Fit_dialog:XPSWindowName
	if (!SVAR_Exists (XPSWindowName))
		return 0
	endif
	NVAR /Z  n_RegWidth = root:XPS_Fit_dialog:n_RegWidth
	NVAR /Z  n_RegHeigth = root:XPS_Fit_dialog:n_RegHeigth
	NVAR /Z  n_InterCtrlDis = root:XPS_Fit_dialog:n_InterCtrlDis
	NVAR /Z n_LoadMenuWidth = root:XPS_fit_dialog:n_LoadMenuWidth
	NVAR /Z nTabHeight = root:XPS_fit_dialog:nTabHeight
	Wave /T CursorColours = root:XPS_Fit_dialog:CursorColours 
	Wave /T CursorNames = root:XPS_Fit_dialog:CursorNames 
	Variable heigth = 0
	
	if (wintype(XPSWindowName)==0)	//checks whether panel exists
		heigth = n_RegHeigth * cnt + 4 * n_InterCtrlDis + 20*3 + nTabHeight
		NVAR /Z nVLeft = root:XPS_Fit_dialog:g_nVLeft
		NVAR /Z nVTop = root:XPS_Fit_dialog:g_nVTop
		variable nleft,ntop
		if (!nvar_exists(nVLeft) || !nvar_exists(nVTop) || nVLeft == 0 || nVTop == 0)
			nLeft = 300 
			nTop = 50
		else
			nleft = nVLeft
			ntop = nVTop
		endif
		NewPanel /K=1 /W=(nLeft,nTop,nLeft + n_NumRegsRow * n_RegWidth +3 ,nTop + heigth ) /N=$XPSWindowName	//make a new panel
		TabControl FitCoefs, pos = {0,5},size = {n_NumRegsRow * n_RegWidth +3, 15},  tablabel(0) = "Fit coefs"
				//abort
		Variable row = 0, col = 0;
		Variable top = 0, left = 0, bottom = 0, right = 0
		Variable n_Peak = 0;
		String s_Colour = ""
		String s_CursName = ""
		String s_CtrlName = ""
		for (row = 0; row < cnt; row += 1)
			for (col = 0; col < n_NumRegsRow; col += 1)
				n_Peak = row * n_NumRegsRow + col +1
				if (n_Peak > n_NumOfRegs)
					break
				endif
				left = 1 + n_RegWidth * col 
				top = 1 + n_RegHeigth * row + nTabHeight
				right = left + n_RegWidth
				bottom = top + n_RegHeigth
				SetDrawEnv linethick=1, fillpat=0
				DrawRect left, top, right, bottom // draw border of region
				
				//abort
				
				SetDrawEnv fsize=14, fstyle=1
				DrawText 100 + left,20 + top, "Peak " + num2str(n_Peak)
				
				SetDrawEnv fsize=8
				DrawText 100 + left,30 + top,"Cursor " + CursorNames[n_Peak-1]  + " (" + CursorColours[n_Peak-1] + ")"
				
				s_CtrlName = "CheckPeak" +  CursorNames[n_Peak-1]
				CheckBox $s_CtrlName,pos={left + 153, top + 6},size={16,14},title="",value = 0, proc=SetCurs
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "int"
				SetVariable $s_CtrlName,pos={left + 7, top + 35},size={119,18},title="Area" ,bodyWidth= 70, value= _NUM:0
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "intHold"
				CheckBox $s_CtrlName,pos={left + 129, top + 37},size={16,14},title="", value = 0
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "intLink"
				PopupMenu $s_CtrlName,pos={left + 146, top + 33},size={68,21}, popvalue=num2str(n_Peak) ,value= #sPopUpValue,  mode = 1
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "intLinkV"
				SetVariable $s_CtrlName,pos={left + 195, top + 34},size={50,18},title=" ", bodyWidth= 50,value = _NUM:1
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "pos"
				SetVariable $s_CtrlName,pos={left + 7, top + 55},size={119,18},title="Position" ,bodyWidth= 70, value = _NUM:0
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "posHold"
				CheckBox $s_CtrlName,pos={left + 129, top + 57},size={16,14},title="", value = 0
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "posLink"
				PopupMenu $s_CtrlName,pos={left + 146, top + 53},size={68,21}, popvalue=num2str(n_Peak) ,value= #sPopUpValue, mode = 1
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "posLinkV"
				SetVariable $s_CtrlName,pos={left + 195, top + 54},size={50,18},title=" ", bodyWidth= 50,value = _NUM:0
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "fwhm"
				SetVariable $s_CtrlName,pos={left + 7, top + 75},size={119,18},title="FWHM" ,bodyWidth= 70, value = _NUM:0
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "fwhmHold"
				CheckBox $s_CtrlName,pos={left + 129, top + 77},size={16,14},title="", value = 0
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "fwhmLink"
				PopupMenu $s_CtrlName,pos={left + 146, top + 73},size={68,21}, popvalue=num2str(n_Peak) ,value= #sPopUpValue, mode = 1
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "fwhmLinkV"
				SetVariable $s_CtrlName,pos={left + 195, top + 74},size={50,18},title=" ", bodyWidth= 50,value = _NUM:1
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "Mix"
				SetVariable $s_CtrlName,pos={left + 7, top + 95},size={119,18},title="Mix" ,bodyWidth= 70, value = _NUM:0
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "MixHold"
				CheckBox $s_CtrlName,pos={left + 129, top + 97},size={16,14},title="", value = 1
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "MixLink"
				PopupMenu $s_CtrlName,pos={left + 146, top + 93},size={68,21}, popvalue=num2str(n_Peak) ,value= #sPopUpValue, mode = 1
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "MixLinkV"
				SetVariable $s_CtrlName,pos={left + 195, top + 94},size={50,18},title=" ", bodyWidth= 50,value = _NUM:1
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "Assym"
				SetVariable $s_CtrlName,pos={left + 7, top + 115},size={119,18},title="Assym" ,bodyWidth= 70, value = _NUM:0
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "AssymHold"
				CheckBox $s_CtrlName,pos={left + 129, top + 117},size={16,14},title="", value = 1
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "AssymLink"
				PopupMenu $s_CtrlName,pos={left + 146, top + 113},size={68,21}, popvalue=num2str(n_Peak) ,value= #sPopUpValue, mode = 1
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "AssymLinkV"
				SetVariable $s_CtrlName,pos={left + 195, top + 114},size={50,18},title=" ", bodyWidth= 50,value = _NUM:1
			endfor
		endfor
		//abort
		TabControl FitCoefs, pos = {0,5},size = {n_NumRegsRow * n_RegWidth +3, 15},  tablabel(1) = "Constrains", proc =XPSFit_SwitchTabs
		
		for (row = 0; row < cnt; row += 1)
			for (col = 0; col < n_NumRegsRow; col += 1)
				n_Peak = row * n_NumRegsRow + col +1
				if (n_Peak > n_NumOfRegs)
					break
				endif
				left = 1 + n_RegWidth * col 
				top = 1 + n_RegHeigth * row + nTabHeight
				right = left + n_RegWidth
				bottom = top + n_RegHeigth
				//SetDrawEnv linethick=1, fillpat=0
				//DrawRect left, top, right, bottom // draw border of region
				
				//SetDrawEnv fsize=14, fstyle=1
				//DrawText 100 + left,20 + top, "Peak " + num2str(n_Peak)
				
				//SetDrawEnv fsize=8
				//DrawText 100 + left,30 + top,"Cursor " + CursorNames[n_Peak-1]  + " (" + CursorColours[n_Peak-1] + ")"
				
				s_CtrlName = "CheckConstPeak" +  CursorNames[n_Peak-1]
				CheckBox $s_CtrlName,pos={left + 153, top + 6},size={16,14},title="",value = 0, disable = 1, proc = XPSFit_SetCnstCsr
				
				s_CtrlName = "useInt" +  CursorNames[n_Peak-1]
				CheckBox $s_CtrlName,pos={left + 2, top + 35},size={16,14},title="",value = 0, disable = 1
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "intMin"
				SetVariable $s_CtrlName,pos={left + 7, top + 35},size={119,18},title="Area" ,bodyWidth= 70, value= _NUM:0, disable = 1
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "intMax"
				SetVariable $s_CtrlName,pos={left + 190, top + 34},size={50,18},title= (" << "), bodyWidth= 50,value = _NUM:inf, disable = 1
				
				s_CtrlName = "usePos" +  CursorNames[n_Peak-1]
				CheckBox $s_CtrlName,pos={left + 2, top + 55},size={16,14},title="",value = 0, disable = 1
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "posMin"
				SetVariable $s_CtrlName,pos={left + 7, top + 55},size={119,18},title="Position" ,bodyWidth= 70, value= _NUM:0, disable = 1
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "posMax"
				SetVariable $s_CtrlName,pos={left + 190, top + 54},size={50,18},title= (" << "), bodyWidth= 50,value = _NUM:inf, disable = 1
				
				s_CtrlName = "usefwhm" +  CursorNames[n_Peak-1]
				CheckBox $s_CtrlName,pos={left + 2, top + 75},size={16,14},title="",value = 0, disable = 1
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "fwhmMin"
				SetVariable $s_CtrlName,pos={left + 7, top + 75},size={119,18},title="FWHM" ,bodyWidth= 70, value= _NUM:0, disable = 1
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "fwhmMax"
				SetVariable $s_CtrlName,pos={left + 190, top + 74},size={50,18},title= (" << "), bodyWidth= 50,value = _NUM:inf, disable = 1
				
				s_CtrlName = "usemix" +  CursorNames[n_Peak-1]
				CheckBox $s_CtrlName,pos={left + 2, top + 95},size={16,14},title="",value = 0, disable = 1
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "mixMin"
				SetVariable $s_CtrlName,pos={left + 7, top + 95},size={119,18},title="Mix" ,bodyWidth= 70, value= _NUM:0, disable = 1
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "mixMax"
				SetVariable $s_CtrlName,pos={left + 190, top + 94},size={50,18},title= (" << "), bodyWidth= 50,value = _NUM:1, disable = 1
				
				s_CtrlName = "useAssym" +  CursorNames[n_Peak-1]
				CheckBox $s_CtrlName,pos={left + 2, top + 115},size={16,14},title="",value = 0, disable = 1
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "assymMin"
				SetVariable $s_CtrlName,pos={left + 7, top + 115},size={119,18},title="Assym" ,bodyWidth= 70, value= _NUM:0, disable = 1
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "AssymMax"
				SetVariable $s_CtrlName,pos={left + 190, top + 114},size={50,18},title= (" << "), bodyWidth= 50,value = _NUM:1, disable = 1
			
			endfor
		endfor
		
		
		
		
		//print "panel"
		//DrawText n_InterCtrlDis,(n_NumOfRegs / n_NumRegsRow) * n_RegHeigth + 5 + 38 + n_InterCtrlDis + nTabHeight, "Fit:"
		Button DoFit, pos={n_InterCtrlDis,(n_NumOfRegs / n_NumRegsRow) * n_RegHeigth + 5 + 20 + n_InterCtrlDis + nTabHeight}, size = {75,48}, title="\Z20Fit", proc=DoFit //fit button
		Button FitAll,pos={2*n_InterCtrlDis + 75,(n_NumOfRegs / n_NumRegsRow) * n_RegHeigth + 5 + 20 + n_InterCtrlDis+ nTabHeight},size={40,48},title="Fit\y-50\x-40All\Z08...",proc=DoMultiFitProc 
		
		Button PlotPeaks, pos={n_InterCtrlDis +150,(n_NumOfRegs / n_NumRegsRow) * n_RegHeigth + 5 + 20 + n_InterCtrlDis+ nTabHeight}, title="Plot Peaks", proc=PlotPeak, size={75,48} //plot peaks button
	
		Button PrintPeakAreas, pos = {250,(n_NumOfRegs / n_NumRegsRow) * n_RegHeigth + 5 + 20 + n_InterCtrlDis+ nTabHeight}, size = {100,20}, title = "Print Areas", proc = PrintPeakAreas
		Button GetFitInfo,pos={250,(n_NumOfRegs / n_NumRegsRow) * n_RegHeigth + 10 + 40 + n_InterCtrlDis+ nTabHeight}, size = {100,20}, title="Get Fit Info\Z08...",proc=GetGFitInfoProc		
		CheckBox plotpeakChecked,pos={355,(n_NumOfRegs / n_NumRegsRow) * n_RegHeigth + 8 + 20 + n_InterCtrlDis+ nTabHeight},size={16,14},title ="", variable= plotpeakChecked	//checks whether to write peak area or not during their plotting
		
		
		PopupMenu GetFrom,pos={390,(n_NumOfRegs / n_NumRegsRow) * n_RegHeigth + 5 + 20 + n_InterCtrlDis+ nTabHeight},size={43,21}
		PopupMenu GetFrom,mode=1,value= GetCoefWaveList(),  proc=GetFrom, title="Get params:"	// popup menu with a list of alll existing waves with coeficcients
		Button GetFromCurs,pos={445,(n_NumOfRegs / n_NumRegsRow) * n_RegHeigth + 10 + 40 + n_InterCtrlDis+ nTabHeight},size={50,20},title="Curs",proc=GetCurs
		Button GetFromGuess,pos={500,(n_NumOfRegs / n_NumRegsRow) * n_RegHeigth + 10 + 40 + n_InterCtrlDis+ nTabHeight},size={50,20},title="Guess",proc=GetGuess
		
	
		//Button GetFromCurs,pos={350,(n_NumOfRegs / n_NumRegsRow) * n_RegHeigth + 5 + 20 + n_InterCtrlDis+ nTabHeight},size={50,20},title="Curs",proc=GetCurs
		
		
		CheckBox bkgrndHold, pos = {n_InterCtrlDis,(n_NumOfRegs / n_NumRegsRow) * n_RegHeigth + 7 + nTabHeight}, size = {16,14}, title = "", value = 1
		SetVariable bkgrnd, pos = {2 * n_InterCtrlDis + 16,(n_NumOfRegs / n_NumRegsRow) * n_RegHeigth + 7 + nTabHeight}, size = {150,20}, title="Background", value = _STR:"0"
		SetVariable lx,  pos={2 * n_InterCtrlDis + 200,(n_NumOfRegs / n_NumRegsRow) * n_RegHeigth + 7 + nTabHeight}, size = {100,20}, title="High BE", value = _STR:""
		SetVariable rx,  pos={3 * n_InterCtrlDis + 300,(n_NumOfRegs / n_NumRegsRow) * n_RegHeigth + 7+ nTabHeight}, size = {100,20}, title="Low BE", value = _STR:""
		CheckBox UseConstrains, pos = {4 * n_InterCtrlDis + 400,(n_NumOfRegs / n_NumRegsRow) * n_RegHeigth + 7+ nTabHeight}, title = "All constrains", disable = 1, proc = XPSFit_UseAllCnst
		button ClearValues pos = {n_NumRegsRow * n_RegWidth  - 50, (n_NumOfRegs / n_NumRegsRow) * n_RegHeigth + 7+ nTabHeight}, title ="Clear", proc = ClearFitValues
		
		PopupMenu pmNumPeaks, pos = {n_NumRegsRow * n_RegWidth  - 105, 5}, mode  = cnt, value = "3;6;9;12;", title = "# of Regions:", proc = FitPanelProc
		
		
		
		Variable nButTop = 50 
		String /G sLoadMenuList = "General Text BE;General Text BE Multi;General Text KE;Matrix BE;Specs format;" 
		String path = "root:sLoadMenuList" 
	else
		GetWindow $("XPS_Fit_Panel"), wsize
		Variable /G root:XPS_Fit_dialog:g_nVLeft = V_left
		Variable /G root:XPS_Fit_dialog:g_nVTop = V_top

		KillWindow $XPSWindowName // kill it! MUST do it in order to get parameters from cursors.
		FitPanel(n_NumOfRegs ) 	
		
				
	endif
end

function FitPanelProc(ctrlName,PopNum,popStr) : PopupMenuControl 
	String ctrlName
	Variable PopNum
	String popStr
	
	FitPanel(str2num(popStr))
		
end

//________________________________________________
function XPSFit_SwitchTabs(sName, nTab)
	string sName
	variable nTab
	
	NVAR /Z n_NumOfRegs = root:XPS_Fit_dialog:n_NumOfRegs
	NVAR /Z  n_NumRegsRow = root:XPS_Fit_dialog:n_NumRegsRow
	Variable cnt = n_NumOfRegs / n_NumRegsRow
	
	Wave /T CursorNames = root:XPS_Fit_dialog:CursorNames 
	
	Variable row = 0, col = 0;
	variable n_Peak
	string s_CtrlName
	
	for (row = 0; row < cnt; row += 1)
			for (col = 0; col < n_NumRegsRow; col += 1)
				n_Peak = row * n_NumRegsRow + col +1
				if (n_Peak > n_NumOfRegs)
					break
				endif
				//left = 1 + n_RegWidth * col 
				//top = 1 + n_RegHeigth * row + nTabHeight
				//right = left + n_RegWidth
				//bottom = top + n_RegHeigth
				//SetDrawEnv linethick=1, fillpat=0
				//DrawRect left, top, right, bottom // draw border of region
				//SetDrawEnv fsize=14, fstyle=1
				//DrawText 100 + left,20 + top, "Peak " + num2str(n_Peak)
				//SetDrawEnv fsize=8
				//DrawText 100 + left,30 + top,"Cursor " + CursorNames[n_Peak-1]  + " (" + CursorColours[n_Peak-1] + ")"
				
				s_CtrlName = "CheckPeak" +  CursorNames[n_Peak-1]
				CheckBox $s_CtrlName, disable = (nTab != 0)
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "int"
				SetVariable $s_CtrlName, disable = (nTab != 0)
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "intHold"
				CheckBox $s_CtrlName, disable = (nTab != 0)
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "intLink"
				PopupMenu $s_CtrlName, disable = (nTab != 0)
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "intLinkV"
				SetVariable $s_CtrlName, disable = (nTab != 0)
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "pos"
				SetVariable $s_CtrlName, disable = (nTab != 0)
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "posHold"
				CheckBox $s_CtrlName, disable = (nTab != 0)
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "posLink"
				PopupMenu $s_CtrlName, disable = (nTab != 0)
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "posLinkV"
				SetVariable $s_CtrlName, disable = (nTab != 0)
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "fwhm"
				SetVariable $s_CtrlName, disable = (nTab != 0)
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "fwhmHold"
				CheckBox $s_CtrlName, disable = (nTab != 0)
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "fwhmLink"
				PopupMenu $s_CtrlName, disable = (nTab != 0)
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "fwhmLinkV"
				SetVariable $s_CtrlName, disable = (nTab != 0)
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "Mix"
				SetVariable $s_CtrlName, disable = (nTab != 0)
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "MixHold"
				CheckBox $s_CtrlName, disable = (nTab != 0)
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "MixLink"
				PopupMenu $s_CtrlName, disable = (nTab != 0)
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "MixLinkV"
				SetVariable $s_CtrlName, disable = (nTab != 0)
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "Assym"
				SetVariable $s_CtrlName, disable = (nTab != 0)
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "AssymHold"
				CheckBox $s_CtrlName, disable = (nTab != 0)
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "AssymLink"
				PopupMenu $s_CtrlName, disable = (nTab != 0)
				
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "AssymLinkV"
				SetVariable $s_CtrlName, disable = (nTab != 0)
				
				
				
				
				
				s_CtrlName = "CheckConstPeak" +  CursorNames[n_Peak-1]
				CheckBox $s_CtrlName,disable = (nTab != 1)
				
				s_CtrlName = "UseInt" +  CursorNames[n_Peak-1]
				CheckBox $s_CtrlName,disable = (nTab != 1)
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "int"
				controlinfo $s_CtrlName
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "intMin"
				SetVariable $s_CtrlName, disable = (nTab != 1)			
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "intMax"
				SetVariable $s_CtrlName, disable = (nTab != 1),  title = (" < " + num2str(v_value) + " < ")
				
				s_CtrlName = "UsePos" +  CursorNames[n_Peak-1]
				CheckBox $s_CtrlName,disable = (nTab != 1)
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "pos"
				controlinfo $s_CtrlName
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "posMin"
				SetVariable $s_CtrlName, disable = (nTab != 1)			
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "posMax"
				SetVariable $s_CtrlName, disable = (nTab != 1),  title = (" < " + num2str(v_value) + " < ")
				
				s_CtrlName = "Usefwhm" +  CursorNames[n_Peak-1]
				CheckBox $s_CtrlName,disable = (nTab != 1)
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "fwhm"
				controlinfo $s_CtrlName
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "fwhmMin"
				SetVariable $s_CtrlName, disable = (nTab != 1)			
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "fwhmMax"
				SetVariable $s_CtrlName, disable = (nTab != 1),  title = (" < " + num2str(v_value) + " < ")
				
				s_CtrlName = "Usemix" +  CursorNames[n_Peak-1]
				CheckBox $s_CtrlName,disable = (nTab != 1)
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "mix"
				controlinfo $s_CtrlName
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "mixMin"
				SetVariable $s_CtrlName, disable = (nTab != 1)			
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "mixMax"
				SetVariable $s_CtrlName, disable = (nTab != 1),  title = (" < " + num2str(v_value) + " < ")
				
				s_CtrlName = "Useassym" +  CursorNames[n_Peak-1]
				CheckBox $s_CtrlName,disable = (nTab != 1)
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "assym"
				controlinfo $s_CtrlName
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "assymMin"
				SetVariable $s_CtrlName, disable = (nTab != 1)			
				s_CtrlName = "c" + CursorNames[n_Peak-1] + "assymMax"
				SetVariable $s_CtrlName, disable = (nTab != 1),  title = (" < " + num2str(v_value) + " < ")
				
				
				
				
				
				
				CheckBox UseConstrains, disable = (nTab != 1)
				
			endfor
		endfor
	
end



//____________________________________________________
function /S GetCoefWaveList()
	
	String sCurDataF = GotoDataFolder()
	//print sCurDataF
	Wave /T /Z wCoefNamesWave = $("wCoefNamesWave")
	if (!WaveExists(wCoefNamesWave))
		return "none"
	endif
	variable i = 0
	string sValue = ""
	string sList = "" 
	for (i = 0; i <  DimSize(wCoefNamesWave,0); i += 1)
		sValue = wCoefNamesWave[i]
		if (stringmatch(sValue, "Coef_*"))
			sList += sValue + ";"
		endif
	endfor
	 sList = SortList(sList, ";", 16)
	SetDataFolder sCurDataF
	return sList
end

//_______________________________________________________

proc XPSFit_SetCnstCsr(sName, nValue)
	string sName
	variable nValue
	
	XPSFit_SetCnstCsrf(sName, nValue)
end

function XPSFit_SetCnstCsrf(sName, nValue)
	string sName
	variable nValue
	
	string sCsrName = sName[strlen(sName) - 1]
	string s_CtrlName
	
	s_CtrlName = "UseInt" +  sCsrName
	CheckBox $s_CtrlName, value = nValue
	
	s_CtrlName = "UsePos" +  sCsrName
	CheckBox $s_CtrlName, value = nValue
	
	s_CtrlName = "Usefwhm" +  sCsrName
	CheckBox $s_CtrlName, value = nValue
	
	s_CtrlName = "UseMix" +  sCsrName
	CheckBox $s_CtrlName, value = nValue
	
	s_CtrlName = "UseAssym" +  sCsrName
	CheckBox $s_CtrlName, value = nValue
	
end

proc XPSFit_UseAllCnst (sName, nValue)
	string sName
	variable nValue
	
	XPSFit_UseAllCnstf (sName, nValue)
end
	
function XPSFit_UseAllCnstf (sName, nValue)
	string sName
	variable nValue
	
	NVAR /Z n_NumOfRegs = root:XPS_Fit_dialog:n_NumOfRegs
	Wave /T CursorNames = root:XPS_Fit_dialog:CursorNames 
	
	variable idx
	string s_CtrlName
	
	for (idx = 0; idx < n_NumOfRegs; idx += 1)
		s_CtrlName = "CheckConstPeak" +  CursorNames[idx]
		CheckBox $s_CtrlName, value = nValue
		XPSFit_SetCnstCsrf (s_CtrlName, nValue)
	endfor
	
end	

//__________________________________________________________

proc SetCurs (name,Value)
	String Name
	Variable Value
	fSetCurs(name,Value)
end

function fSetCurs (name, Value)
	String Name
	Variable Value
	Variable v_value
	String WName = WinName(0,1)
	String TraceName=NameOfWave(CsrWaveRef(A))
	Variable bIsChecked = 0
	Variable nCrsPos = 0

	if (strlen(TraceName) == 0) // if no crs A on any trace
		ControlInfo $("cApos")
		cursor /W = $WName A, $(WaveName("",0,1)), v_value
		CheckBox $("CheckPeakA"), value = 1
	endif
	String NewTraceName=NameOfWave(CsrWaveRef(A))

	NVAR n_NumOfRegs = root:XPS_fit_dialog:n_NumOfRegs
	Variable nNumOfRegs = n_NumOfRegs
	Variable idx = 0
	Wave/T CursorNames = root:XPS_fit_dialog:CursorNames	
	if (cmpstr(name,"CheckPeakA") == 0)
		ControlInfo $("CheckPeakA")
		bIsChecked = v_value
		ControlInfo $("cApos")
		nCrsPos = v_value
		if (bIsChecked)
			cursor /W = $WName A, $NewTraceName, v_value
		else 
			cursor /K A
		endif
		return 0
	endif 
	
	CheckBox $("CheckPeakA"), value = 1
	nNumOfRegs = nNumOfRegs > 10 ? 10 : nNumOfRegs
	for (idx = 1; idx < nNumOfRegs; idx += 1)
		ControlInfo $("CheckPeak" + CursorNames[idx])
		bIsChecked = v_value
		ControlInfo $("c" + CursorNames[idx] + "pos")
		nCrsPos = v_value
		if (bIsChecked)
			cursor /W = $WName $CursorNames[idx], $NewTraceName, nCrsPos
		else
			cursor /K $CursorNames[idx]
		endif
	endfor

	for (idx = nNumOfRegs; idx < 10; idx += 1)
		cursor /K $CursorNames[idx]
	endfor
end

//____________________________________________________________________________________________

function GetGFitInfo()

	Variable idx,i,t

	Wave /T wWaveNamesWave = $("wCoefNamesWave")

	if (!waveExists(wWaveNamesWave))
		return 0
	endif
	
	print "Start calculating areas"
	
	string sCurFOlder = GoToDataFOlder()
	string sListOfWaves = WaveList("*", ";", "WIN:")
	sListOfWaves = SortList(sListOfWaves,";",16);
	
//	duplicate /O wCoefNamesWave wCoefNamesWave0
//	Wave /T wWaveNamesWave = $("wCoefNamesWave0")
//	sort /A, $NameOfWave(wWaveNamesWave), $NameOfWave(wWaveNamesWave)
	variable nDimSize
	string sNameBase = StringFromList(0,sListOfWaves)
	variable nIs2D = 0
	
	if (DimSize($StringFromList(0,sListOfWaves), 1) ) // if 2D wave
		nDimSize =  DimSize ($StringFromList(0,sListOfWaves),1)
		nIs2D = 1
	else  // if list of 1D waves
 		nDimSize = ItemsInList(sListOfWaves)
 		nIs2D = 0
	endif
	
	variable /G g_nDimSize = nDimSize
	string /G g_sNameBase = sNameBase
	string /G g_sListOfWaves = sListOfWaves
	variable /G g_nIs2D = nIs2D
	string /G g_sCurFOlder = sCurFOlder
	
	
	
	variable nwidth, nheight
	nwidth = 5+ 3 * (150 + 5)
	nheight = 5 + 200 + 5 + 20 + 5
	
	make /T/O /N = (12) wListOfAreas
	for (i = 0; i < 12; i += 1)
			wListOfAreas[i]  = "Areas of peak " + num2str(i + 1)
	endfor
	
	make /T/O /N = (12) wListOfPos
	for (i = 0; i < 12; i += 1)
			wListOfPos[i]  = "Positions of peak " + num2str(i + 1)
	endfor
	
	make /T/O /N = (12) wListOfFWHM
	for (i = 0; i < 12; i += 1)
			wListOfFWHM[i]  = "FWHMs of peak " + num2str(i + 1)
	endfor
	
	make /O /N = (12) wListOfSelAreas
	make /O /N = (12) wListOfSelPos
	make /O /N = (12) wListOfSelFWHM
	
	
	newpanel /N=GetFitInfoWin/W = (100,100,100 + nwidth, 100 + nheight) /K = 2
	listbox GetFitInfoAreaLB, pos = {5,5}, size = {150,200}, listwave = wListOfAreas, selWave = wListOfSelAreas, mode  = 10
	listbox GetFitInfoPosLB, pos = {5 + 150 + 5,5}, size = {150,200}, listwave = wListOfPos, selWave = wListOfSelPos, mode  = 10
	listbox GetFitInfoFWHMLB, pos = {5 + 300 + 10,5}, size = {150,200}, listwave = wListOfFWHM, selWave = wListOfSelFWHM, mode  = 10
	button GetFitInfoGetButton, pos = {5, 5 + 200 + 5}, size = {70, 20}, title = "Get info", proc = GetFitInfoGet
	button GetFitInfoCancellButton, pos = {5 + 70 + 5, 5 + 200 + 5}, size = {70, 20}, title = "Cancel", proc = GetFitInfoCancell
	checkbox GetFitInfoDisplayResults, pos = {5 + 70 + 5 + 70 + 5, 5 + 200 + 5}, title = "Display", value = 0
	abort
end

function GetFitInfoCancell(ctrlName)
	string ctrlName
	
	DoWindow /K GetFitInfoWin
	KillWaves wListOfAreas, wListOfPos, wListOfFWHM
end






function GetFitInfoGet(ctrlName)
	string ctrlname
	
	NVAR nDimSize = g_nDimSize
	SVAR  sNameBase = g_sNameBase
	SVAR  sListOfWaves = g_sListOfWaves
	NVAR nIs2D = g_nIs2D
	SVAR sCurFOlder = g_sCurFOlder

	variable i, idx, t
	wave wListOfSelAreas, wListOfSelPos, wListOfSelFWHM
	
	ControlInfo GetFitInfoDisplayResults
	variable bDisplay = v_value
	
	if (wavemax(wListOfSelAreas ) > 0 && bDisplay)
		display
	endif
		
	for (i = 0; i < 12; i += 1)
		if (wListOfSelAreas[i])
			Make /O/N=(nDimSize) $("PAreas_" + sNameBase + "_" + num2str(i + 1))
			
			if (bDisplay)
				AppendToGraph $("PAreas_" + sNameBase + "_" + num2str(i + 1))
			endif
			
			wave wPeakArea = $("PAreas_" + sNameBase + "_" + num2str(i + 1))
			wPeakArea = 0
		else
			KillWaves /Z $("PAreas_" + sNameBase + "_" + num2str(i + 1))
		endif
	endfor

	if (wavemax(wListOfSelPos ) > 0 && bDisplay)
		display
	endif
	for (i = 0; i < 12; i += 1)
		if (wListOfSelPos[i])
			Make /O/N=(nDimSize) $("PPos_" + sNameBase + "_" + num2str(i+ 1))	
			
			if (bDisplay)
				AppendToGraph $("PPos_" + sNameBase + "_" + num2str(i+ 1))	
			endif
			
			wave wPeakPos = $("PPos_" + sNameBase + "_" + num2str(i + 1))
			wPeakPos = 0
		else
			KillWaves  /Z $("PPos_" + sNameBase + "_" + num2str(i+ 1))
		endif
	endfor
	
	if (wavemax(wListOfSelFWHM ) > 0 && bDisplay)
		display
	endif
	for (i = 0; i < 12; i += 1)
		if (wListOfSelFWHM[i])
			Make /O/N=(nDimSize) $("PFWHM_" + sNameBase + "_" + num2str(i + 1))
			
			if (bDisplay)
				AppendToGraph $("PFWHM_" + sNameBase + "_" + num2str(i + 1))
			endif
			
			wave wPeakFWHM = $("PFWHM_" + sNameBase + "_" + num2str(i + 1))
			wPeakFWHM = 0
		else
			KillWaves /Z $("PFWHM_" + sNameBase + "_" + num2str(i + 1))
		endif
	endfor
	
	Make /O/T/N=(nDimSize)$("PNames_" + sNameBase)
	wave/T wPeakNames =  $("PNames_" + sNameBase)
	
	string sWName, sTempW
	
	for (idx = 0; idx < nDimSize; idx += 1)
		//if (wListOfSelAreas[idx] || wListOfSelPos[idx] || wListOfSelFWHM[idx])
			if (nIs2D) // 2D
				sWName = "coef_" + sNameBase + "_" + num2str(idx+1)
			else
				sWName = "coef_" + stringfromlist(idx, sListOfWaves)
			endif
		
		//endif

		if(strlen(sWname))
			wave /Z wCoef = GetCoefWave(sWName)
			if (WaveExists(wCoef))
				for (i = 0; i < (dimSize(wCoef,0) - 1)/5; i += 1)
					//print idx,i,  wcoef[1+5*i]
					wave /Z wPeakArea = $("PAreas_" + sNameBase + "_" + num2str(i + 1))
					wave /Z wPeakPos = $("PPos_" + sNameBase + "_" + num2str(i + 1))
					wave /Z wPeakFWHM = $("PFWHM_" + sNameBase + "_" + num2str(i + 1))
					
					wPeakNames[idx] = sWName
					
					if (wListOfSelAreas[i] )
						wPeakArea[idx][i] = wcoef[1+5*i]
					endif
					
					if (wListOfSelPos[i])
					wPeakPos[idx][i] = wcoef[2+5*i]
					endif
					
					if (wListOfSelFWHM[i])
						wPeakFWHM[idx][i] = wcoef[3+5*i]
					endif
				endfor
				KillWaves $("Link_" + sWName[5,strlen(sWName) - 1])
				KillWaves $("LinkV_" +sWName[5,strlen(sWName) - 1])
				KillWaves $("Hold_" +sWName[5,strlen(sWName) - 1])
				KillWaves $("Use_" +sWName[5,strlen(sWName) - 1])
				KillWaves $("MinC_" +sWName[5,strlen(sWName) - 1])
				KillWaves $("MaxC_" +sWName[5,strlen(sWName) - 1])
				KillWaves $(sWName)
			endif
		endif
		//if (t > nDimSize / 10)
			//t = 0
			//print round((idx /nDimSize * 100 )), "% "	
		//endif
		
		//t+= 1
	endfor
	
	
	
	//KillWaves $("wCoefNamesWave0")
	print "done"
	DoWindow /K GetFitInfoWin
	KillWaves wListOfAreas, wListOfPos, wListOfFWHM
	
	SetDataFolder sCurFolder
	
end
//_______________________________________________________________________________________________________

function SortWaves(sListOfWaves, sWaveSortBy)
	String sListOfWaves, sWaveSortBy
	
	Wave /T wWaveSortBy = $sWaveSortBy
	
	duplicate /O wWaveSortBy $(sWaveSortBy + "s")
	Wave /T wWaveSorted = $(sWaveSortBy + "s")
	
	variable i = 0, j = 0, t = 0
	variable nWaves = itemsinlist(sListOfWaves)
	
	for (i = 0; i < nWaves; i += 1)
		duplicate /O $(StringFromList(i,sListOfWaves)) $(StringFromList(i,sListOfWaves) + "s")
	endfor
	
	Sort /A $(sWaveSortBy + "s"), $(sWaveSortBy + "s")
	
	String sStrA, sStrB
	variable nPnts =  numpnts(wWaveSortBy)
	for (i = 0; i < nPnts; i += 1)
		j = -1
		do 
			j+= 1
			if (j > nPnts)
				break
			endif
		while (!stringmatch(wWaveSorted[j],wWaveSortBy[i]))
		
		for (t = 0; t < nWaves; t += 1)
			Wave wSWave = $(StringFromList(t,sListOfWaves) + "s")
			Wave wWave = $(StringFromList(t,sListOfWaves) )
			wSWave[j] = wWave [i] 
		endfor		
	endfor
	
	for (i = 0; i < nWaves; i += 1)
		duplicate /O $(StringFromList(i,sListOfWaves) + "s") $(StringFromList(i,sListOfWaves) )
		KIllWaves $(StringFromList(i,sListOfWaves) + "s")
	endfor
	
end

//______________________________________________________________
function DoFit (ctrlName) 
	String ctrlName
	
	Wave /Z wTraceName = csrWaveRef(A)
	String sTraceName = NameOfWave(wTraceName) // get name of the fitting wave
	String sWaveDataFolder = GetWavesDataFolder (wTraceName,1)
	String sCurDataFolder = GetDataFolder (1)
	SetDataFolder sWaveDataFolder 
	
	if (strlen(sTraceName) == 0)	
		abort "Cursor A is not on the graph"
	endif
	NVAR n_NumOfRegs = root:XPS_fit_dialog:n_NumOfRegs
	Variable nNumOfRegs = n_NumOfRegs
	WAVE /T CursorNames = root:Xps_fit_dialog:CursorNames
	Variable i = 0
	NVAR nNumOfPeaks = root:XPS_fit_dialog:n_NumOfPeaks
	nNumOfPeaks = 0
	
	for (i = 0; i < nNumOfRegs; i += 1)
		ControlInfo $("CheckPeak" + CursorNames[i])
		if (v_value)
			nNumOfPeaks = i +1
		endif		
	endfor
	//print "numpeaks = ", nNumOfPeaks
	//abort
	String sHoldCheck = CheckLinks(nNumOfPeaks)
	String sConstrainWave = "T_Constrains"
	
	MakeConstrains(nNumOfPeaks)	
	
	makewaves(sTraceName)
	
	String sCoefWave = "Coef_" + sTraceName
	GetCoefWave(sCoefWave)
	//abort
	wave wTraceName = $(sTraceName)
	variable lp, rp
	
	controlinfo $("lx") 
	if (strlen(s_value) == 0)
		lp = 0
	else
		lp = x2pnt($sTraceName,v_value)
	endif
	
	controlinfo $("rx") 
	if (strlen(s_value) == 0)
		rp = numpnts($sTraceName) - 1
	else
		rp = x2pnt($sTraceName,v_value)
	endif
	
	STRUCT stFitFuncStruct fs
	wave fs.wCurLinks = $("Link_" + NameOfWave(wTraceName))
	wave fs.wCurLinkVs =$("LinkV_" + NameOfWave(wTraceName))
	wave fs.wMinC =$("MinC_" + NameOfWave(wTraceName))
	wave fs.wMaxC =$("MaxC_" + NameOfWave(wTraceName))
	wave /t fs.CursorNames = CursorNames
	wave fs.wGLAsArea = $("root:XPS_Fit_dialog:AreaWave")
	fs.nNumOfPeaks = nNumOfPeaks
	//print "ntable"
	variable V_FitError
	//abort

	FuncFit/Q=1/H=sHoldcheck /NTHR=0 XPS_1GLAs,$sCoefWave, wTraceName[lp,rp] /D /C = $sConstrainWave /STRC = fs// DO FIT!!!
	//wave w = $sCoefWave
	//wave wc = $sConstrainWave
	//print w
	
	//print wTraceName[112],  sHoldcheck, w, wc
	//abort
	if (GetBit(1,V_FitError))
		V_FitError = 0
		FuncFit/Q=1/H=sHoldcheck /NTHR=0 XPS_1GLAs,$sCoefWave, wTraceName[lp,rp] /D /C = $sConstrainWave /STRC = fs// DO FIT!!!
	endif
//abort
	SaveCoefWave(sCoefWave)
	GetFrom ("",0,sCoefWave)	
	SetDataFOlder sCurDataFolder
	
end
//_______________________________________________________________________

function /S CheckLinks (nNumOfPeaks) //proc checks whether the peak is linked to any other peaks or not
	Variable nNumOfPeaks
	
	Wave /T CursorNames = root:XPS_fit_dialog:CursorNames
	String sListOfLinkControls
	String sListOfHoldControls
	NVAR nNumOfRegs = root:XPS_fit_dialog:n_NumOfRegs
	String sCurLinkName = ""
	String sCurHoldName = ""	
	Variable v_value
	String s_value = ""
	ControlInfo $("bkgrndHold")
	String sHoldCheck = num2str(v_value)
	
		
	
	Variable idx = 0
	Variable i = 0
	for (idx = 0; idx < nNumOfPeaks; idx += 1) // for each cursor
		sListOfLinkControls = ControlNameList("", ";", ("c" + CursorNames[idx] + "*Link"))
		sListOfHoldControls = ControlNameList("", ";", ("c" + CursorNames[idx] + "*Hold"))
		
		for (i = 0; i< 5; i += 1)
			sCurLinkName = StringFromList (i, sListOfLinkControls)
			sCurHoldName = StringFromList (i, sListOfHoldControls)
			
			ControlInfo $sCurLinkName
			if (str2num(s_value) != idx+1)
				CheckBox $sCurHoldName, value= 1
			endif
			
			ControlInfo $("CheckPeak" + CursorNames[idx])
			if (v_value)
				ControlInfo $(sCurHoldName)
				sHoldCheck += num2str(v_value)
			else
				sHoldCheck += num2str(1)
			endif
			
		endfor		
	endfor		
	return sHoldCheck
end
//_______________________________________________________________________________

function /S MakeConstrains (nNumOfPeaks)
	variable nNumOfPeaks
	
	make /O/T/N = 0 T_Constrains 
	Wave /T T_Constrains 
	T_Constrains = ""
	String sCoefNum = "K"
	Variable v_value
	Wave /T CursorNames = root:XPS_fit_dialog:CursorNames
	Variable idx = 0
	Variable t = -1
	for (idx = 0; idx < nNumOfPeaks; idx += 1) // for each peak
		Controlinfo $("CheckPeak" + CursorNames[idx])
		if (v_value)
			
			ControlInfo $("c" + CursorNames[idx] + "intHold") 
			if (!v_value) // if fit area
				t += 1
				
				controlinfo $("useInt" + CursorNames[idx])
				if (v_value) // if use constrains
					
					controlinfo $("c" +  CursorNames[idx] + "intMin")
					sCoefNum = "K" + num2str(5 * (idx + 1) - 4) + " >" + num2str(v_value)
					Redimension /N=(numpnts(T_Constrains) + 1) T_Constrains
					T_Constrains[t] = sCoefNum
					 t += 1
					
					controlinfo $("c" +  CursorNames[idx] + "intMax")
					sCoefNum = "K" + num2str(5 * (idx + 1) - 4) + " <" + num2str(v_value)
					Redimension /N=(numpnts(T_Constrains) + 1) T_Constrains
					T_Constrains[t] = sCoefNum
					 
					
				else
					sCoefNum = "K" + num2str(5 * (idx + 1) - 4) + " > 0.000001 "
					Redimension /N=(numpnts(T_Constrains) + 1) T_Constrains
					T_Constrains[t] = sCoefNum
				endif	
			endif
			
			ControlInfo $("c" + CursorNames[idx] + "posHold") 
			if (!v_value) // if fit area
				t += 1
				
				controlinfo $("usepos" + CursorNames[idx])
				if (v_value) // if use constrains
					
					controlinfo $("c" +  CursorNames[idx] + "posMin")
					sCoefNum = "K" + num2str(5 * (idx + 1) - 3) + " >" + num2str(v_value)
					Redimension /N=(numpnts(T_Constrains) + 1) T_Constrains
					T_Constrains[t] = sCoefNum
					 t += 1
					
					controlinfo $("c" +  CursorNames[idx] + "posMax")
					sCoefNum = "K" + num2str(5 * (idx + 1) - 3) + " <" + num2str(v_value)
					Redimension /N=(numpnts(T_Constrains) + 1) T_Constrains
					T_Constrains[t] = sCoefNum
				endif	
			endif
			
			ControlInfo $("c" + CursorNames[idx] + "fwhmHold") 
			if (!v_value) // if fit area
				t += 1
				
				controlinfo $("usefwhm" + CursorNames[idx])
				if (v_value) // if use constrains
					
					controlinfo $("c" +  CursorNames[idx] + "fwhmMin")
					sCoefNum = "K" + num2str(5 * (idx +1) - 2 ) + " >" + num2str(v_value)
					Redimension /N=(numpnts(T_Constrains) + 1) T_Constrains
					T_Constrains[t] = sCoefNum
					 t += 1
					
					controlinfo $("c" +  CursorNames[idx] + "fwhmMax")
					sCoefNum = "K" + num2str(5 * (idx + 1) -2 ) + " <" + num2str(v_value)
					Redimension /N=(numpnts(T_Constrains) + 1) T_Constrains
					T_Constrains[t] = sCoefNum
				endif	
			endif
			
			ControlInfo $("c" + CursorNames[idx] + "MixHold")
			if (!v_value) 
				controlinfo $("usemix" + CursorNames[idx])
				if (v_value) // if use constrains
					t += 1
					controlinfo $("c" +  CursorNames[idx] + "mixMin")
					sCoefNum = "K" + num2str(5 * (idx + 1) - 1 ) + " >" + num2str(v_value)
					Redimension /N=(numpnts(T_Constrains) + 1) T_Constrains
					T_Constrains[t] = sCoefNum
					 t += 1
					
					controlinfo $("c" +  CursorNames[idx] + "mixMax")
					sCoefNum = "K" + num2str(5 * (idx + 1) -1 ) + " <" + num2str(v_value)
					Redimension /N=(numpnts(T_Constrains) + 1) T_Constrains
					T_Constrains[t] = sCoefNum
				else	
					t += 1
					sCoefNum = "K" + num2str(5 * (idx + 1) - 1) + " > 0.01 "
					Redimension /N=(numpnts(T_Constrains) + 1) T_Constrains
					T_Constrains[t] = sCoefNum
					t += 1 
					sCoefNum = "K" + num2str(5 * (idx + 1) - 1) + " < 0.99 "
					Redimension /N=(numpnts(T_Constrains) + 1) T_Constrains
					T_Constrains[t] = sCoefNum
				endif
			endif
			
			ControlInfo $("c" + CursorNames[idx] + "AssymHold")
			if (!v_value) 
				controlinfo $("useassym" + CursorNames[idx])
				if (v_value) // if use constrains
					t += 1
					controlinfo $("c" +  CursorNames[idx] + "assymMin")
					sCoefNum = "K" + num2str(5 * (idx + 1) ) + " >" + num2str(v_value)
					Redimension /N=(numpnts(T_Constrains) + 1) T_Constrains
					T_Constrains[t] = sCoefNum
					 t += 1
					
					controlinfo $("c" +  CursorNames[idx] + "assymMax")
					sCoefNum = "K" + num2str(5 * (idx + 1) ) + " <" + num2str(v_value)
					Redimension /N=(numpnts(T_Constrains) + 1) T_Constrains
					T_Constrains[t] = sCoefNum
				else	
					t += 1
					sCoefNum = "K" + num2str(5 * (idx + 1) ) + " > 0.01 "
					Redimension /N=(numpnts(T_Constrains) + 1) T_Constrains
					T_Constrains[t] = sCoefNum
					t += 1 
					sCoefNum = "K" + num2str(5 * (idx + 1) ) + " < 0.99 "
					Redimension /N=(numpnts(T_Constrains) + 1) T_Constrains
					T_Constrains[t] = sCoefNum
				endif
			endif
		endif
	endfor
//abort
end
//___________________________________________________________________________
function plotpeak(ctrlName) : ButtonControl
	String ctrlName
	
	String sCurFolder = GotoDataFolder()
	
	Wave /Z wCurWave = csrWaveRef(A)
	
	if (strlen(NameOfWave(wCurWave)) == 0)
		Cursor /A = 1 A $(WaveName("",0,1)) 	leftx($(WaveName("",0,1)))
		Wave wCurWave = csrWaveRef(A)
	endif
	String sCurWave = NameOfWave (wCurWave)
	
	String sTraceInfo = TraceInfo ("", sCurWave,0)
	Variable nTraceOffset = str2Num(sTraceInfo[strsearch(sTraceInfo,"offset(x)=",0)+13,strsearch(sTraceInfo,"offset(x)=",0)+18])
	String sCoefWave = "Coef_" + sCurWave
	Wave /Z wCoefWave = GetCoefWave(sCoefWave)
	wave wGLAaArea = $("root:XPS_Fit_dialog:AreaWave")
	
	if (WaveExists(wCoefWave) == 0)
		makewaves(sCurWave)
		Wave wCoefWave = GetCoefWave(sCoefWave)
	endif

	NVAR nNumOfPeaks = root:XPS_fit_dialog:n_NumOfPeaks
	NVAR n_NumOfRegs = root:XPS_fit_dialog:n_NumOfRegs
	Variable nNumOfRegs = n_NumOfRegs
	Wave /T CursorNames = root:XPS_fit_dialog:CursorNames
	nNumOfPeaks = 0
	Variable i = 0
	for (i = 0; i < nNumOfRegs; i += 1)
		ControlInfo $("CheckPeak" + CursorNames[i])
		if (v_value)
			nNumOfPeaks = i + 1
		endif
	endfor
	
	Variable nNumPnts = numpnts(wCoefWave)
	String sPeakWave
	String sFitPeakWave = "fit_" + sCurWave
	duplicate /O  wCurWave $sFitPeakWave
	Wave wFitPeakWave = $sFitPeakWave
	wFitPeakWave = 0
	
	if (cmpstr(WaveList(sFitPeakWave, "","WIN:"), sFitPeakWave)!=0)
			AppendToGraph wFitPeakWave
	endif
	
	ControlInfo $("bkgrnd")
	wFitPeakWave += v_value
	ModifyGraph offset ($sFitPeakWave) = {0,nTraceOffset}
	WAVE PeakColours = root:XPS_fit_dialog:PeakColours
	Variable nArea,nPos,nFWHM,nMix,nAssym
	Controlinfo $("plotpeakChecked")
	
	if (v_value)
		print "Peak Areas:"
	endif
	
	String sPrintArea
	Variable nTotArea = 0
	
	for (i = 0; i < nNumOfRegs; i += 1)
		sPeakWave = sCurWave + "_" + num2str(i+1)
		if (strsearch (TraceNameList("",";", 1),sPeakWave,0) != -1)
			RemoveFromGraph $sPeakWave
		endif
	endfor
	
	variable nInt = 0
	
	for (i = 0; i < nNumOfRegs; i += 1)
		sPeakWave = sCurWave + "_" + num2str(i+1)
		if (strsearch (TraceNameList("",";", 1),sPeakWave,0) != -1)
			RemoveFromGraph $sPeakWave
		endif
		ControlInfo $("CheckPeak" + CursorNames[i])
		if (v_value)
			duplicate /O  wCurWave $sPeakWave
			Wave wPeakWave = $sPeakWave
			Controlinfo $("c" + CursorNames[i] + "int")
			nArea = v_value
			Controlinfo $("c" + CursorNames[i] + "Pos")
			nPos = v_value
			
			if (i < 10)
				Cursor /A = 1 $(CursorNames[i]) $sCurWave 	nPos
				//print CursorNames[i], nPos
			endif
			
			Controlinfo $("c" + CursorNames[i] + "FWHM")
			nFwhm = v_value
			Controlinfo $("c" + CursorNames[i] + "Mix")
			nMix = v_value
			Controlinfo $("c" + CursorNames[i] + "Assym")
			nAssym = v_value
			
			nInt = nArea/(nFWHM*wGLAaArea(nAssym)(nMix))
			//print nAssym, nMix, wGLAaArea(nAssym)(nMix), nInt, nArea
			
			
			
			wPeakWave = XPS_GLAs(nInt, nPos, nFwhm, nMix, nAssym,x)
			wFitPeakWave += wPeakWave
			ControlInfo $("bkgrnd")
			wPeakWave += v_value
			AppendToGraph wPeakWave 
			sPrintArea = sPeakWave + ": " + num2str(area($sPeakWave,-inf,inf))
			nTotArea += area($sPeakWave,-inf,inf)
		
			Controlinfo $("plotpeakChecked")
			if (v_value)
				print sPrintArea
			endif 
			
			ModifyGraph offset ($sPeakWave) = {0,nTraceOffset}
			ModifyGraph rgb($sPeakWave) = ( PeakColours[i][0], PeakColours[i][1], PeakColours[i][2])
		else
			if (i < 10)
				Cursor /K $(CursorNames[i])
			endif 
		endif
	endfor
	
	if (v_value)
		print "Total area: ", nTotArea	
	endif
	KillWaves $sCoefWave
	KillWaves $("Link_" + sCoefWave[5,strlen(sCoefWave) - 1])
	KillWaves $("LinkV_" + sCoefWave[5,strlen(sCoefWave) - 1])
	KillWaves $("Hold_" + sCoefWave[5,strlen(sCoefWave) - 1])
	KillWaves $("Use_" + sCoefWave[5,strlen(sCoefWave) - 1])
	KillWaves $("MinC_" + sCoefWave[5,strlen(sCoefWave) - 1])
	KillWaves $("MaxC_" + sCoefWave[5,strlen(sCoefWave) - 1])
	SetDataFolder sCurFolder
end
//_______________________________________________________________________	
//function plotpeak1(wave_name)
 //wave wave_name
// make /O/N=6 wp
// wave wp 
 //variable peak, peak_as
 
	
//wp[0]=wave_name[2]
//wp[1]=wave_name[3]
//wp[2]=wave_name[4]
//wp[3]=wave_name[5]

//Peak=exp( -2.772589 * (1-wp[2]) * ( (X-wp[0])/ wp[1] )^2  ) / (4 * wp[2] * ( (X-wp[0]) / wp[1] )^2  +  1 )

//if (X > wp[0])
//		Peak_as = Peak * (peak + (1 - peak) * exp(wp[3]*(X-wp[0]) / wp[1]) )
//	else
//		Peak_as = Peak
//	endif

//return Peak_as*wave_name[1]+wave_name[0]
//end
//____________________________________________________________________________________________

function makewaves(sTraceName)
	String sTraceName
	
	NVAR n_NumOfRegs = root:XPS_fit_dialog:n_NumOfRegs
	Variable nNumOfRegs = n_NumOfRegs
	WAVE /T CursorNames = root:Xps_fit_dialog:CursorNames
	Variable i = 0
	NVAR nNumOfPeaks = root:XPS_fit_dialog:n_NumOfPeaks
	Variable v_value, nMaxPeak = 0
	nNumOfPeaks = 0
	
	for (i = 0; i < nNumOfRegs; i += 1)
		ControlInfo $("CheckPeak" + CursorNames[i])
		if (v_value)
			nNumOfPeaks = i +1
			nMaxPeak = i
		endif		
	endfor

	nNumOfPeaks = nMaxPeak + 1
	String sCoefWave = "Coef_" + sTraceName
	Make /D/O /N = (5 * nNumOfRegs + 1)  $sCoefWave
	Wave wCoefWave = $sCoefWave

	ControlInfo $("bkgrnd")
	wCoefWave[0] = v_value
	for (i = 0; i < nNumOfRegs; i += 1)
		ControlInfo $("CheckPeak" + CursorNames[i])
		if (v_value)
			ControlInfo $("c" + CursorNames[i] + "Int")
			wCoefWave[5*i + 1] = v_value
		else
			wCoefWave[5 * i + 1] = 0
		endif
			
		ControlInfo $("c" + CursorNames[i] + "Pos")
		wCoefWave[5 * i + 2] = v_value
		
		ControlInfo $("c" + CursorNames[i] + "FWHM")
		wCoefWave[5 * i + 3] = v_value
			
		ControlInfo $("c" + CursorNames[i] + "Mix")
		wCoefWave[5 * i + 4] = v_value
		
		ControlInfo $("c" + CursorNames[i] + "Assym")
		wCoefWave[5 * i + 5] = v_value	
	endfor
	
	String sLinkVWave = "LinkV_" + sTraceName
	Make/D/O /N = (5 * nNumOfPeaks + 1) $sLinkVWave
	Wave wLinkVWave = $sLinkVWave
	SVAR sCurLinkVs = root:XPS_fit_dialog:g_CurLinkVs
	sCurLinkVs = sLinkVWave
	
	wLinkVWave[0] = 0
	for (i = 0; i < nNumOfPeaks; i += 1)
		ControlInfo $("CheckPeak" + CursorNames[i])
		if (v_value)
			ControlInfo $("c" + CursorNames[i] + "IntLinkV")
			wLinkVWave[5*i + 1] = v_value
		else
			wLinkVWave[5 * i + 1] = 0
		endif
			
		ControlInfo $("c" + CursorNames[i] + "PosLinkV")
		wLinkVWave[5 * i + 2] = v_value
			
		ControlInfo $("c" + CursorNames[i] + "FWHMLinkV")
		wLinkVWave[5 * i + 3] = v_value
			
		ControlInfo $("c" + CursorNames[i] + "MixLinkV")
		wLinkVWave[5 * i + 4] = v_value
			
		ControlInfo $("c" + CursorNames[i] + "AssymLinkV")
		wLinkVWave[5 * i + 5] = v_value				
	endfor
			
	String sLinkWave = "Link_" + sTraceName
	Make/D/O /N = (5 * nNumOfPeaks + 1) $sLinkWave
	Wave wLinkWave = $sLinkWave
	SVAR sCurLinks = root:XPS_fit_dialog:g_CurLinks
	sCurLinks = sLinkWave
		
	wLinkWave[0] = 0
	for (i = 0; i < nNumOfPeaks; i += 1)
		ControlInfo $("c" + CursorNames[i] + "IntLink")
		wLinkWave[5*i + 1] = str2num(s_value)
			
		ControlInfo $("c" + CursorNames[i] + "PosLink")
		wLinkWave[5 * i + 2] = str2num(s_value)
			
		ControlInfo $("c" + CursorNames[i] + "FWHMLink")
		wLinkWave[5 * i + 3] = str2num(s_value)
			
		ControlInfo $("c" + CursorNames[i] + "MixLink")
		wLinkWave[5 * i + 4] = str2num(s_value)
			
		ControlInfo $("c" + CursorNames[i] + "AssymLink")
		wLinkWave[5 * i + 5] = str2num(s_value)
	endfor
		
		
			
	String sHoldWave = "Hold_" + sTraceName
	Make/D/O /N = (5 * nNumOfPeaks + 1) $sHoldWave
	Wave wHoldWave = $sHoldWave
	SVAR sCurHold = root:XPS_fit_dialog:g_CurHold
	sCurHold = sHoldWave
		
	wHoldWave[0] = 0
	for (i = 0; i < nNumOfPeaks; i += 1)
		ControlInfo $("c" + CursorNames[i] + "IntHold")
		wHoldWave[5*i + 1] = v_value
			
		ControlInfo $("c" + CursorNames[i] + "PosHold")
		wHoldWave[5 * i + 2] = v_value
			
		ControlInfo $("c" + CursorNames[i] + "FWHMHold")
		wHoldWave[5 * i + 3] = v_value
			
		ControlInfo $("c" + CursorNames[i] + "MixHold")
		wHoldWave[5 * i + 4] = v_value
			
		ControlInfo $("c" + CursorNames[i] + "AssymHold")
		wHoldWave[5 * i + 5] = v_value
	endfor
	
	
	string sUseWave = "Use_" + sTraceName
	Make/D/O /N = (5 * nNumOfPeaks + 1) $sUseWave
	Wave wUseWave = $sUseWave
	SVAR sCurUse = root:XPS_fit_dialog:g_CurUse
	sCurUse = sUseWave
		
	wUseWave[0] = 0
	for (i = 0; i < nNumOfPeaks; i += 1)
		ControlInfo $("UseInt" + CursorNames[i])
		wUseWave[5*i + 1] = v_value
			
		ControlInfo $("UsePos" + CursorNames[i] )
		wUseWave[5 * i + 2] = v_value
			
		ControlInfo $("UseFWHM" + CursorNames[i] )
		wUseWave[5 * i + 3] = v_value
			
		ControlInfo $("UseMix" + CursorNames[i])
		wUseWave[5 * i + 4] = v_value
			
		ControlInfo $("UseAssym" + CursorNames[i])
		wUseWave[5 * i + 5] = v_value
	endfor
	
	
	
	String sMinCWave = "MinC_" + sTraceName
	Make/D/O /N = (5 * nNumOfPeaks + 1) $sMinCWave
	Wave wMinCWave = $sMinCWave
	SVAR sCurMinC = root:XPS_fit_dialog:g_CurMinC
	sCurMinC = sMinCWave
		
	wMinCWave[0] = 0
	for (i = 0; i < nNumOfPeaks; i += 1)
		ControlInfo $("c" + CursorNames[i] + "IntMin")
		wMinCWave[5*i + 1] = v_value
			
		ControlInfo $("c" + CursorNames[i] + "PosMin")
		wMinCWave[5 * i + 2] = v_value
			
		ControlInfo $("c" + CursorNames[i] + "FWHMMin")
		wMinCWave[5 * i + 3] = v_value
			
		ControlInfo $("c" + CursorNames[i] + "MixMin")
		wMinCWave[5 * i + 4] = v_value
			
		ControlInfo $("c" + CursorNames[i] + "AssymMin")
		wMinCWave[5 * i + 5] = v_value
	endfor

	String sMaxCWave = "MaxC_" + sTraceName
	Make/D/O /N = (5 * nNumOfPeaks + 1) $sMaxCWave
	Wave wMaxCWave = $sMaxCWave
	SVAR sCurMaxC = root:XPS_fit_dialog:g_CurMaxC
	sCurMaxC = sMaxCWave
		
	wMaxCWave[0] = 0
	for (i = 0; i < nNumOfPeaks; i += 1)
		ControlInfo $("c" + CursorNames[i] + "IntMax")
		wMaxCWave[5*i + 1] = v_value
			
		ControlInfo $("c" + CursorNames[i] + "PosMax")
		wMaxCWave[5 * i + 2] = v_value
			
		ControlInfo $("c" + CursorNames[i] + "FWHMMax")
		wMaxCWave[5 * i + 3] = v_value
			
		ControlInfo $("c" + CursorNames[i] + "MixMax")
		wMaxCWave[5 * i + 4] =v_value
			
		ControlInfo $("c" + CursorNames[i] + "AssymMax")
		wMaxCWave[5 * i + 5] = v_value
	endfor
	
	
	SaveCoefWave(sCoefWave)
	
end
//__________________________________________________________________________
function GetFrom (ctrlName,PopNum,popStr) : PopupMenuControl 
	String ctrlName
	Variable PopNum
	String popStr
	
	String sCurFolder = GoToDataFolder()
	if (WaveExists($popStr))
		duplicate /O $popStr $(popstr + "D")
		Wave wCoefName = GetCoefWave(popStr)
		Duplicate /O $(popstr + "D") $popstr
		KillWaves $(popstr + "D")
	else
		Wave wCoefName = GetCoefWave(popStr)
	endif
	
	NVAR nNumOfPeaks = root:XPS_fit_dialog:n_NumOfPeaks
	NVAR nNumOfRegs = root:XPS_fit_dialog:n_NumOfRegs
	//print "getfrom npeaks = ", nNumOfPeaks
	Wave /T CursorNames = root:XPS_fit_dialog:CursorNames
	
	String sCurLinks = "Link_" + popStr[5, strlen(popStr) - 1]	
	Wave wCurLinks = $sCurLinks
	
	String sCurLinkVs = "LinkV_" + popStr[5, strlen(popStr) - 1]
	Wave wCurLinkVs = $sCurLinkVs
	
	String sCurHold = "Hold_" + popStr[5, strlen(popStr) - 1]	
	Wave wCurHold = $sCurHold
	
	String sCurUse = "Use_" + popStr[5, strlen(popStr) - 1]	
	Wave wCurUse = $sCurUse
	
	String sCurMinC = "MinC_" + popStr[5, strlen(popStr) - 1]
	Wave wCurMinC = $sCurMinC
	
	String sCurMaxC = "MaxC_" + popStr[5, strlen(popStr) - 1]
	Wave wCurMaxC = $sCurMaxC
	
	nNumOfPeaks = (DimSize(wCoefName,0) - 1) / 5
	nNumOfPeaks = nNumOfPeaks > nNumOfRegs ? nNumOfRegs : nNumOfPeaks
	Variable v_value
	Variable i
	SVAR sPopUpValue = root:XPS_Fit_dialog:s_PopUpValue;
	SetVariable $("bkgrnd"), value = _NUM:wCoefName[0]
	for (i = 0; i < nNumOfPeaks; i+= 1)
		SetVariable $("c" + CursorNames[i] + "Int"), value = _NUM:wCoefName[5 * i + 1]
		SetVariable $("c" + CursorNames[i] + "Pos"), value = _NUM:wCoefName[5 * i + 2]
		SetVariable $("c" + CursorNames[i] + "FWHM"), value = _NUM:wCoefName[5 * i + 3]
		SetVariable $("c" + CursorNames[i] + "Mix"), value = _NUM:wCoefName[5 * i + 4]
		SetVariable $("c" + CursorNames[i] + "Assym"), value = _NUM:wCoefName[5 * i + 5]
		
		if (WaveExists(wCurLinkVs))
			SetVariable $("c" + CursorNames[i] + "IntLinkV"), value = _NUM:wCurLinkVs[5 * i + 1]
			SetVariable $("c" + CursorNames[i] + "PosLinkV"), value = _NUM:wCurLinkVs[5 * i + 2]
			SetVariable $("c" + CursorNames[i] + "FWHMLinkV"), value = _NUM:wCurLinkVs[5 * i + 3]
			SetVariable $("c" + CursorNames[i] + "MixLinkV"), value = _NUM:wCurLinkVs[5 * i + 4]
			SetVariable $("c" + CursorNames[i] + "AssymLinkV"), value = _NUM:wCurLinkVs[5 * i + 5]
		endif
		
		if (WaveExists(wCurLinks))
			PopUpMenu $("c" + CursorNames[i] + "IntLink"), popvalue =num2str(wCurLinks[5 * i + 1]), value = #sPopUpValue, mode =1
			PopUpMenu $("c" + CursorNames[i] + "PosLink"), popvalue = num2str(wCurLinks[5 * i + 2]), value = #sPopUpValue, mode =1
			PopUpMenu $("c" + CursorNames[i] + "FWHMLink"), popvalue = num2str(wCurLinks[5 * i + 3]), value = #sPopUpValue, mode =1
			PopUpMenu $("c" + CursorNames[i] + "MixLink"), popvalue = num2str(wCurLinks[5 * i + 4]), value = #sPopUpValue, mode =1
			PopUpMenu $("c" + CursorNames[i] + "AssymLink"), popvalue = num2str(wCurLinks[5 * i + 5]), value = #sPopUpValue, mode =1
		endif
		
		if (WaveExists(wCurHold))
			CheckBox $("c" + CursorNames[i] + "IntHold"), value = wCurHold[5 * i + 1]
			CheckBox $("c" + CursorNames[i] + "PosHold"), value = wCurHold[5 * i + 2]
			CheckBox $("c" + CursorNames[i] + "FWHMHold"), value =wCurHold[5 * i + 3]
			CheckBox $("c" + CursorNames[i] + "MixHold"), value = wCurHold[5 * i + 4]
			CheckBox $("c" + CursorNames[i] + "AssymHold"), value = wCurHold[5 * i + 5]
		endif
		
		if (WaveExists(wCurUse))
			CheckBox $("UseInt" + CursorNames[i]), value = wCurUse[5 * i + 1]
			CheckBox $( "UsePos" + CursorNames[i]), value = wCurUse[5 * i + 2]
			CheckBox $("UseFWHM" + CursorNames[i]), value = wCurUse[5 * i + 3]
			CheckBox $("UseMix" + CursorNames[i] ), value = wCurUse[5 * i + 4]
			CheckBox $("UseAssym" + CursorNames[i]), value = wCurUse[5 * i + 5]
		endif
		
		if (WaveExists(wCurMinC))
			SetVariable $("c" + CursorNames[i] + "IntMin"), value = _NUM:wCurMinC[5 * i + 1]
			SetVariable $("c" + CursorNames[i] + "PosMin"), value = _NUM:wCurMinC[5 * i + 2]
			SetVariable $("c" + CursorNames[i] + "FWHMMin"), value = _NUM:wCurMinC[5 * i + 3]
			SetVariable $("c" + CursorNames[i] + "MixMin"), value = _NUM:wCurMinC[5 * i + 4]
			SetVariable $("c" + CursorNames[i] + "AssymMin"), value = _NUM:wCurMinC[5 * i + 5]
		endif
		
		if (WaveExists(wCurMaxC))
			SetVariable $("c" + CursorNames[i] + "IntMax"), value = _NUM:wCurMaxC[5 * i + 1]
			SetVariable $("c" + CursorNames[i] + "PosMax"), value = _NUM:wCurMaxC[5 * i + 2]
			SetVariable $("c" + CursorNames[i] + "FWHMMax"), value = _NUM:wCurMaxC[5 * i + 3]
			SetVariable $("c" + CursorNames[i] + "MixMax"), value = _NUM:wCurMaxC[5 * i + 4]
			SetVariable $("c" + CursorNames[i] + "AssymMax"), value = _NUM:wCurMaxC[5 * i + 5]
		endif


		if (wCoefName[5 * i + 1] == 0)
			CheckBox $("CheckPeak" + CursorNames[i]), value = 0
		else
			CheckBox $("CheckPeak" + CursorNames[i]), value = 1 
			ControlInfo $("c" + CursorNames[i] + "pos")
			Wave/Z wCurWave = csrWaveRef(A)
			if (waveexists(wCurWave))
				String sCurWave = NameOfWave (wCurWave)
				if (i < 10)
					cursor $CursorNames[i], $sCurWave, v_value
				endif
			else
				if (i < 10)
					cursor $CursorNames[i], $(WaveName("",0,1)), v_value
				endif
			endif
		endif
	endfor
	KillWaves $popStr
	KillWaves $sCurLinks
	KillWaves $sCurLinkVs
	KillWaves $sCurHold
	KillWaves $sCurUse
	KillWaves $sCurMinC
	KillWaves $sCurMaxC

	if (nNumOfPeaks < nNumOfRegs)
		for (i = nNumOfPeaks; i < nNumOfRegs; i += 1)
			CheckBox $("CheckPeak" + CursorNames[i]), value = 0
		endfor
	endif
	
	plotpeak("")
	SetDataFolder sCurFolder
end
//______________________________

function SaveCoefWave(sCoefWaveName) // NOTE: make sure "Link_" and "LinkV_" waves exist!
	String sCoefWaveName
	
	Wave wCoefWaveName = $(sCoefWaveName) 
	Wave /Z wLinkWaveName = $("Link_" + sCoefWaveName[5,strlen(sCoefWaveName) - 1])
	Wave /Z wLinkVWaveName = $("LinkV_" + sCoefWaveName[5,strlen(sCoefWaveName) - 1])
	Wave /Z wHoldWaveName = $("Hold_" + sCoefWaveName[5,strlen(sCoefWaveName) - 1])
	Wave /Z wUseWaveName = $("Use_" + sCoefWaveName[5,strlen(sCoefWaveName) - 1])
	Wave /Z wMinCWaveName = $("MinC_" + sCoefWaveName[5,strlen(sCoefWaveName) - 1])
	Wave /Z wMaxCWaveName = $("MaxC_" + sCoefWaveName[5,strlen(sCoefWaveName) - 1])
	
	NVAR n_MaxRegs = root:XPS_fit_dialog:n_MaxRegs
	
	if (WaveExists ($("wCoef2DWave")) == 0)
		NVAR n_MaxRegs = root:XPS_fit_dialog:n_MaxRegs
		Make /O /N= (n_MaxRegs * 5 + 1,1,5) wCoef2DWave // wave to keep all fit paraeters
		Make /T /O /N=1 wCoefNamesWave // wave to keep al fitted wave names
	endif

	Wave w2DWave =  $("wCoef2DWave")
	Wave /T wWaveNamesWave = $("wCoefNamesWave")			
	variable i = 0
	variable nPos = FindStrInWave (sCoefWaveName, $(NameOfWave(wWaveNamesWave))) 

	if (nPos == -1) // if coef was never existed
		Redimension /N= (n_MaxRegs*5 + 1, DimSize(w2DWave,1) + 1, 7) $(NameOfWave(w2DWave)) // add one column in wave
		Redimension /N= (DimSize(wWaveNamesWave,0) + 1) wWaveNamesWave // add one row in the wave
		for (i = 0; i < DimSize (wCoefWaveName,0); i += 1)
			w2DWave[i][ DimSize(w2DWave,1) - 1][0] = wCoefWaveName[i] //copy fit coefficients
			w2DWave[i][ DimSize(w2DWave,1) - 1][1] = wLinkWaveName[i] // copy links
			w2DWave[i][ DimSize(w2DWave,1) - 1][2] = wLinkVWaveName[i] // copy link values
			w2DWave[i][ DimSize(w2DWave,1) - 1][3] = waveExists(wHoldWaveName) ? wHoldWaveName[i] : 0 // copy link values
			w2DWave[i][ DimSize(w2DWave,1) - 1][4] = waveExists(wUseWaveName) ? wUseWaveName[i] : 0 // copy link values
			w2DWave[i][ DimSize(w2DWave,1) - 1][5] = waveexists(wMinCWaveName) ? wMinCWaveName[i] : 0 // copy min constrains
			w2DWave[i][ DimSize(w2DWave,1) - 1][6] = waveexists(wMaxCWaveName) ? wMaxCWaveName[i] : 0 // copy max constrains
		endfor
		
		wWaveNamesWave [DimSize(wWaveNamesWave,0) - 1] = sCoefWaveName// copy coef name
		KillWaves $sCoefWaveName
		KillWaves $NameOfWave(wLinkWaveName)
		KillWaves $NameOfWave(wLinkVWaveName)
		KillWaves $NameOfWave(wHoldWaveName)
		KillWaves $NameOfWave(wUseWaveName)
		KillWaves $NameOfWave(wMinCWaveName)
		KillWaves $NameOfWave(wMaxCWaveName)
		
		return DimSize(wCoefNamesWave,0) - 1
	else // if coef exists and written
		for (i = 0; i < DimSize (wCoefWaveName,0); i += 1)
			w2DWave[i][ nPos][0] = wCoefWaveName[i]
			w2DWave[i][ nPos][1] = wLinkWaveName[i]
			w2DWave[i][ nPos][2] = wLinkVWaveName[i]
			w2DWave[i][ nPos][3] =  waveExists(wHoldWaveName) ? wHoldWaveName[i] : 0
			w2DWave[i][ nPos][4] = waveExists(wUseWaveName) ? wUseWaveName[i] : 0
			w2DWave[i][ nPos][5] = waveexists(wMinCWaveName) ? wMinCWaveName[i] : 0 
			w2DWave[i][ nPos][6] =  waveexists(wMaxCWaveName) ? wMaxCWaveName[i] : 0 
		endfor
		KillWaves $sCoefWaveName
		KillWaves $NameOfWave(wLinkWaveName)
		KillWaves $NameOfWave(wLinkVWaveName)
		KillWaves $NameOfWave(wHoldWaveName)
		KillWaves $NameOfWave(wUseWaveName)
		KillWaves $NameOfWave(wMinCWaveName)
		KillWaves $NameOfWave(wMaxCWaveName)
		return nPos
	endif
		
end

function FindStrInWave (sName,wWave)
	String sName
	Wave /T wWave

	variable i = 0, j =0
	for (i = 0; i < DimSize(wWave,0); i += 1)
		if (stringmatch (sName,wWave[i]))
			
			if (DimSize(wWave,1))
				return str2num(wWave[i][1])
			else
				return i
			endif
		endif
	endfor
	return -1
end

function /WAVE GetCoefWave (sCoefWaveName)
	string sCoefWaveName
	
	if (!strlen(sCoefWaveName))
		return $"-1"
	endif
	
	NVAR /Z nNumOfPeaks =  root:XPS_fit_dialog:n_NumOfPeaks
	if (WaveExists ($("wCoef2DWave")) == 0)
		NVAR n_MaxRegs = root:XPS_fit_dialog:n_MaxRegs
		Make /O /N= (n_MaxRegs * 5 + 1, 1, 7) wCoef2DWave
		Make /T /O /N=1 wCoefNamesWave
	endif

	Wave w2DWave =  $("wCoef2DWave")
	Wave /T wWaveNamesWave = $("wCoefNamesWave")			
	variable nPos = FindStrInWave(sCoefWaveName,wWaveNamesWave)
	variable i = 0, t = 0, k = 0
	
	if (nPos != -1)
		i = DimSize (w2DWave,0) -1
	
		do
			if (w2DWave[i-4][npos][0] != 0 )
				t = i
				break
			endif
			i -= 5
		while (i >= 0)
	
		t = i > 0 ? t : 60
		nNumOfPeaks = (t )/5 
		//t += 5
		
 		Make /O /N= (nNumOfPeaks * 5 +1) $sCoefWaveName
		Make /O /N= (nNumOfPeaks * 5 +1) $("Link_" + sCoefWaveName[5,strlen(sCoefWaveName) - 1])
		Make /O /N= (nNumOfPeaks * 5 +1) $("LinkV_" + sCoefWaveName[5,strlen(sCoefWaveName) - 1])
		Make /O /N= (nNumOfPeaks * 5 +1) $("Hold_" + sCoefWaveName[5,strlen(sCoefWaveName) - 1])
		Make /O /N= (nNumOfPeaks * 5 +1) $("Use_" + sCoefWaveName[5,strlen(sCoefWaveName) - 1])
		Make /O /N= (nNumOfPeaks * 5 +1) $("MinC_" + sCoefWaveName[5,strlen(sCoefWaveName) - 1])
		Make /O /N= (nNumOfPeaks * 5 +1) $("MaxC_" + sCoefWaveName[5,strlen(sCoefWaveName) - 1])
		
		Wave wCoefWaveName = $sCoefWaveName
		Wave wLinkWaveName = $("Link_" + sCoefWaveName[5,strlen(sCoefWaveName) - 1])
		Wave wLinkVWaveName =$("LinkV_" + sCoefWaveName[5,strlen(sCoefWaveName) - 1])
		Wave wHoldWaveName =$("Hold_" + sCoefWaveName[5,strlen(sCoefWaveName) - 1])
		Wave wUseWaveName =$("Use_" + sCoefWaveName[5,strlen(sCoefWaveName) - 1])
		Wave wMinCWaveName = $("MinC_" + sCoefWaveName[5,strlen(sCoefWaveName) - 1])
		Wave wMaxCWaveName =$("MaxC_" + sCoefWaveName[5,strlen(sCoefWaveName) - 1])
		
		for (i = 0; i < DimSize (wCoefWaveName,0); i += 1)
			wCoefWaveName [i] = w2DWave [i][nPos][0]
			wLinkWaveName [i] = w2DWave [i][nPos][1]
			wLinkVWaveName [i] = w2DWave [i][nPos][2]
			wHoldWaveName [i] = w2DWave [i][nPos][3]
			wUseWaveName [i] = w2DWave [i][nPos][4]
			wMinCWaveName [i] = w2DWave [i][nPos][5]
			wMaxCWaveName [i] = w2DWave [i][nPos][6]
		endfor
		
		return wCoefWaveName
	else
		return $"-1"		
	endif
	
end

 
//________________________________________________________________________________
function GetCurs(ctrlName) 
 	String ctrlName
 	
 	String sCurFolder = GoToDataFolder()
 	NVAR nNumOfRegs = root:XPS_fit_dialog:n_NumOfRegs
 	Wave /T CursorNames = root:XPS_fit_dialog:CursorNames
 	SVAR sPopUpValue = root:XPS_Fit_dialog:s_PopUpValue
 	wave wGLAaArea = $("root:XPS_Fit_dialog:AreaWave")
	String sCsrWave
	sCsrWave = CsrWave(A)
	
	if (strlen(sCsrWave) == 0)
		Abort ("No cursor A on any wave")
	endif
	String sCsrAWave = sCsrWave
	Variable nNumOfPeaks = GetNumOfCursOnGraph()
	String sCsrName
	
 	Variable i = 0
 	variable nvalue = 0
 	variable sCheck = (nNumOfRegs < 10 ? nNumOfRegs  : 10) 
 	
 	for (i = 0; i < sCheck; i+= 1)
		
		sCsrName = CursorNames[i]
		
				
		if (strlen(CsrWave($sCsrName)) != 0)
			nvalue = xcsr($sCsrName)
			CheckBox $("CheckPeak" + CursorNames[i]), value = 1
			SetVariable $("c" + CursorNames[i] + "Int"), value = _NUM : vcsr($sCsrName)*0.5 * wGLAaArea[0.01][ 0.01]
			SetVariable $("c" + CursorNames[i] + "Pos"), value = _NUM : xcsr($sCsrName)
		else
					CheckBox $("CheckPeak" + CursorNames[i]), value = 0
			SetVariable $("c" + CursorNames[i] + "Int"), value = _NUM : 0
		endif

		SetVariable $("c" + CursorNames[i] + "FWHM"), value = _NUM : 0.5
		SetVariable $("c" + CursorNames[i] + "Mix"), value = _NUM : 0.01
		SetVariable $("c" + CursorNames[i] + "Assym"), value = _NUM : 0.01
		
		//SetVariable $("c" + CursorNames[i] + "IntLinkV"), value = _NUM : 1
		//SetVariable $("c" + CursorNames[i] + "PosLinkV"), value = _NUM : 0
		//SetVariable $("c" + CursorNames[i] + "FWHMLinkV"), value = _NUM : 1
		//SetVariable $("c" + CursorNames[i] + "MixLinkV"), value = _NUM :  1
		//SetVariable $("c" + CursorNames[i] + "AssymLinkV"), value = _NUM : 1
	
		//PopUpMenu $("c" + CursorNames[i] + "IntLink"), popvalue = num2str(i + 1), value = #sPopUpValue, mode =1
		//PopUpMenu $("c" + CursorNames[i] + "PosLink"), popvalue = num2str(i + 1), value = #sPopUpValue, mode =1
		//PopUpMenu $("c" + CursorNames[i] + "FWHMLink"), popvalue = num2str(i + 1), value = #sPopUpValue, mode =1
		//PopUpMenu $("c" + CursorNames[i] + "MixLink"), popvalue = num2str(i + 1), value = #sPopUpValue, mode =1
		//PopUpMenu $("c" + CursorNames[i] + "AssymLink"), popvalue = num2str(i + 1), value = #sPopUpValue, mode =1
	
	endfor
 	
	if (!WaveExists(GetCoefWave("Coef_" + sCsrWave)))
		makewaves(sCsrWave)
	endif

	plotpeak("")
 	SetDataFOlder sCurFolder
 	
 end 
 
 //___________________________________________________________
 function GetGuess(ctrlName)
 	string ctrlName
 	
 	NVAR n_NumOfRegs = root:XPS_fit_dialog:n_NumOfRegs
	Variable nNumOfRegs = n_NumOfRegs
	Wave/T CursorNames = root:XPS_fit_dialog:CursorNames	
	
 	
 	wave wWave = WaveRefIndexed("",0,1)	
 	duplicate/O wWave $(NameOfWave(wWave) + "s")
 	wave wSWave = $(NameOfWave(wWave) + "s")
 	variable nMagicCoef = 7 + floor( getwmeanstdev(NameOfWave(wWave),4) * 1000)
 	if (mod(nMagicCoef,2 ) == 0)
 		nMagicCoef += 1
 	endif
 	nMagicCoef = nMagicCoef > 25 ? 25 : nMagicCoef
 	//print nMagicCoef
 	Smooth  /S= 2  nMagicCoef, wSWave
 	Differentiate wSWave /D = $(NameOfWave(wSWave) + "d")
 	wave wSDWave = $(NameOfWave(wSWave) + "d")
 	Smooth  /S= 2 nMagicCoef, wSDWave
 	
 	Differentiate wSDWave /D = $(NameOfWave(wSDWave) + "d")
 	wave wSDDWave = $(NameOfWave(wSDWave) + "d")
 	Smooth  /S= 2 5, wSDDWave
	
 	variable nYThreshold =  WaveMin(wSDDWave) * 0.05
 	variable i
 	for (i =0; i < numpnts(wsddWave); i += 1)
 		wSDDWave[i] = wSDDWave[i] > nYThreshold ? 0 :wSDDWave[i]
 	endfor

 	Differentiate wSDDWave /D = $(NameOfWave(wSDDWave) + "d")
 	wave wSDDDWave = $(NameOfWave(wSDDWave) + "d")
 	Smooth  5, wSDDDWave
 	
 	String WName = WinName(0,1)
 	variable t
 	for (i = 0; i < 10; i +=1)
 		cursor /K $CursorNames[i] 
 	endfor
 	//
 	for (i = numpnts(wSDDDWave) - 2; i > 1; i -= 1)
 		if (wSDDDWave[i-1] > wSDDDWave[i] && wSDDDWave[i] < 0 && wSDDDWave[i - 1] > 0 && wSWave[i] > 0.15*WaveMax(wSWave))
 			//print pnt2x(wSDDDWave,i)
 			if (t < 10)
 				cursor $CursorNames[t], $NameOfwave(wWave), pnt2x(wSDDDWave,i)
 				t += 1
 			endif
 		endif
 	endfor
 	
 	//GetCurs("GetFromCurs")	
 	Killwaves wSWave, wSDWave, wSDDWave, wSDDDWave

 end
 
 function getwmeanstdev (sWave,nB)
 	string sWave
 	variable nB
 	
 	duplicate / O $swave $(swave+"stdev")
 	wave wSwave = $(swave+"stdev")
 	wSwave = 0
 	wave wWave = $sWave
 	variable nNumBins = floor (numpnts($sWave) / nB)
 
 	variable idx,i
 	variable nMean, stdev,stdevmean
 	for(idx = 0; idx < 40 ; idx += 1)
 		nMean = 0
 		for (i = idx; i < idx + nB; i += 1)
 			nMean += wWave[i]
 		endfor
 		nMean /= nB
 		stdev = 0
 		for (i = idx; i < idx + nB; i += 1)
 			stdev += (wWave[i] - nMean) ^ 2
 		endfor
 		
 		wSWave[idx + (nB - 1) / 2] = sqrt(stdev / nB)
 		stdevmean += sqrt(stdev / nB)
 	endfor
 	//print stdevmean / 40, WaveMax(wWave), stdevmean / 40 / WaveMax(wWave)
 	KillWaves $(swave+"stdev")
 	return stdevmean / 40 / WaveMax(wWave)
 	
 end
 
 
 
 
//___________________________________________________________

function ClearFitValues (ctrlname) : buttonControl
	string ctrlName
	
	String sCurFolder = GoToDataFolder()
 	NVAR nNumOfRegs = root:XPS_fit_dialog:n_NumOfRegs
 	SVAR sPopUpValue = root:XPS_Fit_dialog:s_PopUpValue
 	Wave /T CursorNames = root:XPS_fit_dialog:CursorNames


 	
 	variable sCheck = (nNumOfRegs < 10 ? nNumOfRegs  : 10) 
 	variable i
 	string s_CtrlName
 	
 	controlinfo $("FitCoefs")
 	if (v_value == 0)
 		for (i = 0; i < sCheck; i+= 1)
			SetVariable $("c" + CursorNames[i] + "Int"), value = _NUM : 0
			SetVariable $("c" + CursorNames[i] + "Pos"), value = _NUM : 0
			SetVariable $("c" + CursorNames[i] + "FWHM"), value = _NUM : 0.5
			SetVariable $("c" + CursorNames[i] + "Mix"), value = _NUM : 0.01
			SetVariable $("c" + CursorNames[i] + "Assym"), value = _NUM : 0.01
			
			SetVariable $("c" + CursorNames[i] + "IntLinkV"), value = _NUM : 1
			SetVariable $("c" + CursorNames[i] + "PosLinkV"), value = _NUM : 0
			SetVariable $("c" + CursorNames[i] + "FWHMLinkV"), value = _NUM : 1
			SetVariable $("c" + CursorNames[i] + "MixLinkV"), value = _NUM :  1
			SetVariable $("c" + CursorNames[i] + "AssymLinkV"), value = _NUM : 1
		
			PopUpMenu $("c" + CursorNames[i] + "IntLink"), popvalue = num2str(i + 1), value = #sPopUpValue, mode =1
			PopUpMenu $("c" + CursorNames[i] + "PosLink"), popvalue = num2str(i + 1), value = #sPopUpValue, mode =1
			PopUpMenu $("c" + CursorNames[i] + "FWHMLink"), popvalue = num2str(i + 1), value = #sPopUpValue, mode =1
			PopUpMenu $("c" + CursorNames[i] + "MixLink"), popvalue = num2str(i + 1), value = #sPopUpValue, mode =1
			PopUpMenu $("c" + CursorNames[i] + "AssymLink"), popvalue = num2str(i + 1), value = #sPopUpValue, mode =1
		
		endfor
 	endif
 	
 	if (v_value == 1)
			for (i = 0; i < sCheck; i+= 1)
				s_CtrlName = "c" + CursorNames[i] + "intMin"
				SetVariable $s_CtrlName,value= _NUM:0
				s_CtrlName = "c" + CursorNames[i] + "intMax"
				SetVariable $s_CtrlName,value = _NUM:inf
				
				s_CtrlName = "c" + CursorNames[i] + "posMin"
				SetVariable $s_CtrlName,value= _NUM:0
				s_CtrlName = "c" + CursorNames[i] + "posMax"
				SetVariable $s_CtrlName,value = _NUM:inf
				
				s_CtrlName = "c" + CursorNames[i] + "fwhmMin"
				SetVariable $s_CtrlName,value= _NUM:0
				s_CtrlName = "c" + CursorNames[i] + "fwhmMax"
				SetVariable $s_CtrlName,value = _NUM:inf
				
				s_CtrlName = "c" + CursorNames[i] + "mixMin"
				SetVariable $s_CtrlName,value= _NUM:0
				s_CtrlName = "c" + CursorNames[i] + "mixMax"
				SetVariable $s_CtrlName,value = _NUM:1
				
				s_CtrlName = "c" + CursorNames[i] + "assymMin"
				SetVariable $s_CtrlName,value= _NUM:0
				s_CtrlName = "c" + CursorNames[i] + "assymMax"
				SetVariable $s_CtrlName,value = _NUM:1
			endfor
 	endif
 	SetDataFOlder sCurFolder
	
	
end





//__________________________________________________

function GetNumOfCursOnGraph()
	
	NVAR n_NumOfRegs = root:XPS_fit_dialog:n_NumOfRegs
	Variable nNumOfRegs = n_NumOfRegs > 10 ? 10 : n_NumOfRegs
	WAVE /T CursorNames = root:Xps_fit_dialog:CursorNames
	Variable i = 0
	NVAR nNumOfPeaks = root:XPS_fit_dialog:n_NumOfPeaks
	Variable v_value
	nNumOfPeaks = 0
	String splus = ""

	for (i = 0; i < nNumOfRegs; i += 1)
		splus = CsrWave($(CursorNames[i]))
		if (strlen(splus) != 0)
			nNumOfPeaks = i +1
		endif		
	endfor
	return nNumOfPeaks
end

//___________________________________________________________
//
//	Written by Georg Held

ThreadSafe Function XPS_GLAs(nInt, nPos, nFWHM, nMix, nAssym, X)
	Variable X,nInt,nPos,nFWHM,nMix,nAssym //
	wave wGLAaArea 
	
	Variable peak, peak_as
	
	// 5 coefficients

	// wp[0] = p_int
	// wp[1] = p_pos
	// wp[2] = p_fwhm
	// wp[3] = p_mix
	// wp[4] = p_assym
	
// peak
	peak = exp( -2.772589 * (1-nMix) * ( (X-nPos)/ nFWHM )^2  ) / (4 * nMix * ( (X-nPos) / nFWHM )^2  +  1)
// asymm. peak

// exponential asymmetry:	
	if (X-nPos > 0)
		peak_as =peak*(peak + (1 - peak) * exp(nAssym*(X-nPos) / nFWHM) )
	else
		peak_as = peak
	endif
	
	return nInt*peak_as
End


ThreadSafe Function XPS_1GLAs(s) : FitFunc
	STRUCT stFitFuncStruct &s
	
	Wave w = s.w
	Variable X = s.x
	variable nNumOfPeaks = s.nNumOfPeaks
	WAVE wCurLinks = s.wCurLinks
	WAVE wCurLinkVs = s.wCurLinkVs
	WAVE /T CursorNames = s.CursorNames
	wave wGLAsArea = s.wGLAsArea

	Variable peak
	Variable totpeak
	Variable nArea, nPos, nFwhm, nMix, nAssym
	Variable V_Value
	String S_Value





	Variable i = 0
	
	for (i = 0; i < nNumOfPeaks; i += 1)
		
		if (i + 1 == wCurLinks[5 * i + 1])
			nArea = w[5 * i + 1]
		else
			nArea = w[5 * (wCurLinks[5 * i + 1] - 1) + 1] * wCurLinkVs[5 * i + 1]
			w[5 * i + 1] = nArea
		endif
	
		if (i + 1 == wCurLinks[5 * i + 2])
			nPos = w[5 * i + 2]
		else
			nPos = w[5 * (wCurLinks[5 * i + 2] - 1) + 2] + wCurLinkVs[5 * i + 2]
			w[5 * i + 2] = nPos
		endif
		
		if (i + 1 == wCurLinks[5 * i + 3])
			nFWHM = w[5 * i + 3]
		else
			nFWHM = w[5 * (wCurLinks[5 * i + 3] - 1) + 3] * wCurLinkVs[5 * i + 3]
			w[5 * i + 3] = nFwhm
		endif
				
		if (i + 1 == wCurLinks[5 * i + 4])
			nMix = w[5 * i + 4]
		else
			nMix = w[5 * (wCurLinks[5 * i + 4] - 1) + 4] * wCurLinkVs[5 * i + 4]
			w[5 * i + 4] = nMix
		endif
		
		if (i + 1 == wCurLinks[5 * i + 5])
			nAssym = w[5 * i + 5]
		else
			nAssym = w[5 * (wCurLinks[5 * i + 5] - 1) + 5] * wCurLinkVs[5 * i + 5]
			w[5 * i + 5] = nAssym
		endif
		
		Variable nInt = nArea/(nFWHM*wGLAsArea(nAssym)(nMix))
		peak = XPS_GLAs(nInt, nPos,nFwhm, nMix,nAssym,X)
		totpeak += peak
	endfor
	
	
	

	return w[0] + totpeak 
End

//____________________________________________________________________

function DoMultiFit ()
	
	DoAlert 1, "Continue?"
	If (v_flag == 2)
		abort
	endif
	
	variable idx = 0,i = 0, t = 0, j = 0
	DoWindow /F $("XPS_Fit_Panel")
	String sCurDF = GotoDataFolder()
	
	
	NVAR n_NumOfRegs = root:XPS_fit_dialog:n_NumOfRegs
	Variable nNumOfRegs = n_NumOfRegs
	WAVE /T CursorNames = root:Xps_fit_dialog:CursorNames
	NVAR nNumOfPeaks = root:XPS_fit_dialog:n_NumOfPeaks
	//Variable v_value
	nNumOfPeaks = 0
	
	for (i = 0; i < nNumOfRegs; i += 1)
		ControlInfo $("CheckPeak" + CursorNames[i])
		if (v_value)
			nNumOfPeaks = i +1
		endif		
	endfor
	
	String sHoldCheck = CheckLinks(nNumOfPeaks)
	
	String sConstrainWave = "T_Constrains" 
	MakeConstrains(nNumOfPeaks)	
	wave /T wConstrainWave = $("T_Constrains")

	variable nDimSize = 0
	String sListOfGraphs = StringFromList(0,WaveList("*", ";", "WIN:")) // get wave graph on the graph
	variable n2DType = DimSize($sListOfGraphs,1) 
	string sListOfWaves = ""

	silent 1
	print "Start fit at", time()
		
		
	if (!n2DType) // if one dimentional waves		
		sListOfWaves = WaveList("*", ";", "WIN:") // list of all wavesin the graph
		 sListOfWaves = SortList(sListOfWaves,";",16);
		XPSFit_MakeMatrix(sListOfWaves, "") // get 2D matrx
		sListOfGraphs = StringFromList(0,sListOfWaves) + "_M"  //name of 2D matrix
	endif

		variable nTime0 = datetime
		wave wListOfGraphs = $(sListOfGraphs)
		nDimSize = DimSize($sListOfGraphs,0)
		variable lp, rp
		controlinfo $("lx") 
		if (strlen(s_value) == 0)
			lp = 0
		else
			lp = x2pnt($sListOfGraphs,v_value)
		endif
	
		controlinfo $("rx")
		if (strlen(s_value) == 0)
			rp = numpnts($sListOfGraphs) - 1
		else
			rp = x2pnt($sListOfGraphs,v_value)
		endif
		
		variable nNumOfThreads = ThreadProcessorCount
		variable threadGroup = ThreadGroupCreate(nNumOfThreads)
		
		String sTListOfGraphs
		variable nThreadCount
		variable nNumGraphTot = DimSize($sListOfGraphs,1)
		variable nNumGraphsThread
		nNumOfThreads = nNumGraphTot > nNumOfThreads * 2 ? nNumOfThreads : 1
		
		
		print "Total number of spectra: ", nNumGraphTot
		print "NUmber of threads: ", nNumOfThreads

		make /O/N=(nNumOfPeaks * 5 + 1) $("Coef_" + sListOfGraphs ) // single spectrum coef wave
		make /O/N=(nNumOfPeaks * 5 + 1) $("Link_" + sListOfGraphs ) // single spectrum link wave
		make /O/N=(nNumOfPeaks * 5 + 1) $("LinkV_" + sListOfGraphs ) // single spectrum linkV wave
		make /O/N=(nNumOfPeaks * 5 + 1) $("Hold_" + sListOfGraphs ) // single spectrum linkV wave
		make /O/N=(nNumOfPeaks * 5 + 1) $("Use_" + sListOfGraphs ) // single spectrum linkV wave
		make /O/N=(nNumOfPeaks * 5 + 1) $("MinC_" + sListOfGraphs ) // single spectrum link wave
		make /O/N=(nNumOfPeaks * 5 + 1) $("MaxC_" + sListOfGraphs ) // single spectrum linkV wave

		wave wCoefWave = $("Coef_" + sListOfGraphs )
		wave wLinkWave =  $("Link_" + sListOfGraphs )
		wave wLinkVWave = $("LinkV_" + sListOfGraphs )
		wave wHoldWave = $("Hold_" + sListOfGraphs )
		wave wUseWave = $("Use_" + sListOfGraphs )
		wave wMinCWave =  $("MinC_" + sListOfGraphs )
		wave wMaxCWave = $("MaxC_" + sListOfGraphs )
			
		ControlInfo $("bkgrnd")
		wCoefWave[0] = v_value

		for (i = 0; i < nNumOfRegs; i += 1)
	
			ControlInfo $("CheckPeak" + CursorNames[i])
			if (v_value)
				ControlInfo $("c" + CursorNames[i] + "Int")
				wCoefWave[5*i + 1] = v_value
			else
				wCoefWave[5 * i + 1] = 0
			endif
			
			ControlInfo $("c" + CursorNames[i] + "Pos")
			wCoefWave[5 * i + 2] = v_value
			
			ControlInfo $("c" + CursorNames[i] + "FWHM")
			wCoefWave[5 * i + 3] = v_value
				
			ControlInfo $("c" + CursorNames[i] + "Mix")
			wCoefWave[5 * i + 4] = v_value
			
			ControlInfo $("c" + CursorNames[i] + "Assym")
			wCoefWave[5 * i + 5] = v_value	
		endfor
			
			
		wLinkVWave[0] = 0
		for (i = 0; i < nNumOfPeaks; i += 1)
			ControlInfo $("CheckPeak" + CursorNames[i])
			if (v_value)
				ControlInfo $("c" + CursorNames[i] + "IntLinkV")
				wLinkVWave[5*i + 1] = v_value
			else
				wLinkVWave[5 * i + 1] = 0
			endif
			
			ControlInfo $("c" + CursorNames[i] + "PosLinkV")
			wLinkVWave[5 * i + 2] = v_value
				
			ControlInfo $("c" + CursorNames[i] + "FWHMLinkV")
			wLinkVWave[5 * i + 3] = v_value
				
			ControlInfo $("c" + CursorNames[i] + "MixLinkV")
			wLinkVWave[5 * i + 4] = v_value
				
			ControlInfo $("c" + CursorNames[i] + "AssymLinkV")
			wLinkVWave[5 * i + 5] = v_value				
		endfor
	
		wLinkWave[0] = 0
		for (i = 0; i < nNumOfPeaks; i += 1)
			ControlInfo $("c" + CursorNames[i] + "IntLink")
			wLinkWave[5*i + 1] = str2num(s_value)
				
			ControlInfo $("c" + CursorNames[i] + "PosLink")
			wLinkWave[5 * i + 2] = str2num(s_value)
				
			ControlInfo $("c" + CursorNames[i] + "FWHMLink")
			wLinkWave[5 * i + 3] = str2num(s_value)
				
			ControlInfo $("c" + CursorNames[i] + "MixLink")
			wLinkWave[5 * i + 4] = str2num(s_value)
				
			ControlInfo $("c" + CursorNames[i] + "AssymLink")
			wLinkWave[5 * i + 5] = str2num(s_value)
		endfor
			
		wHoldWave[0] = 0
		for (i = 0; i < nNumOfPeaks; i += 1)
			ControlInfo $("c" + CursorNames[i] + "IntHold")
			wHoldWave[5*i + 1] = v_value
				
			ControlInfo $("c" + CursorNames[i] + "PosHold")
			wHoldWave[5 * i + 2] =v_value
				
			ControlInfo $("c" + CursorNames[i] + "FWHMHold")
			wHoldWave[5 * i + 3] = v_value
				
			ControlInfo $("c" + CursorNames[i] + "MixHold")
			wHoldWave[5 * i + 4] = v_value
				
			ControlInfo $("c" + CursorNames[i] + "AssymHold")
			wHoldWave[5 * i + 5] = v_value
		endfor
		
		wUseWave[0] = 0
		for (i = 0; i < nNumOfPeaks; i += 1)
			ControlInfo $("UseInt" + CursorNames[i] )
			wUseWave[5*i + 1] = v_value
				
			ControlInfo $("UsePos" + CursorNames[i])
			wUseWave[5 * i + 2] =v_value
				
			ControlInfo $("UseFWHM"+ CursorNames[i])
			wUseWave[5 * i + 3] = v_value
				
			ControlInfo $("UseMix"+ CursorNames[i])
			wUseWave[5 * i + 4] = v_value
				
			ControlInfo $("UseAssym"+ CursorNames[i] )
			wUseWave[5 * i + 5] = v_value
		endfor
		
		
		wMinCWave[0] = 0
		for (i = 0; i < nNumOfPeaks; i += 1)
			ControlInfo $("c" + CursorNames[i] + "IntMin")
			wMinCWave[5*i + 1] =v_value
				
			ControlInfo $("c" + CursorNames[i] + "PosMin")
			wMinCWave[5 * i + 2] =v_value
				
			ControlInfo $("c" + CursorNames[i] + "FWHMMin")
			wMinCWave[5 * i + 3] = v_value
				
			ControlInfo $("c" + CursorNames[i] + "MixMin")
			wMinCWave[5 * i + 4] = v_value
				
			ControlInfo $("c" + CursorNames[i] + "AssymMin")
			wMinCWave[5 * i + 5] = v_value
		endfor
		
		wMaxCWave[0] = 0
		for (i = 0; i < nNumOfPeaks; i += 1)
			ControlInfo $("c" + CursorNames[i] + "IntMax")
			wMaxCWave[5*i + 1] = v_value
				
			ControlInfo $("c" + CursorNames[i] + "PosMax")
			wMaxCWave[5 * i + 2] = v_value
				
			ControlInfo $("c" + CursorNames[i] + "FWHMMax")
			wMaxCWave[5 * i + 3] = v_value
				
			ControlInfo $("c" + CursorNames[i] + "MixMax")
			wMaxCWave[5 * i + 4] = v_value
				
			ControlInfo $("c" + CursorNames[i] + "AssymMax")
			wMaxCWave[5 * i + 5] = v_value
		endfor
		STRUCT stFitFuncStruct s // create structure to pass it later to fake fitfunction
		wave s.wCurLinks = wLinkWave
		wave s.wCurLinkVs = wLinkVWave
		wave s.wMinC= wMinCWave
		wave s.wMaXC = wMaxCWave
		wave /t s.CursorNames = CursorNames
		wave s.wGLAsArea = $("root:XPS_Fit_dialog:AreaWave")
		wave wAreaWave = $("root:XPS_Fit_dialog:AreaWave")
		s.nNumOfPeaks = nNumOfPeaks
						
		// copy first wave from matrix:
		Make /O /N=(DimSize(wListOfGraphs,0)) $("tmpdata")
		wave wTmpData = $("tmpData")
		for (i = 0; i < DimSize(wListOfGraphs,0); i += 1)
			wTmpData[i] = wListOfGraphs[i][0]		
			//print 	wTmpData[i]
		endfor	
		//abort
		setScale x,  DimOffset(wListOfGraphs,0), nDimSize * DimDelta (wListOfGraphs,0) +  DimOffset(wListOfGraphs,0), $("tmpData")
		//String sTHoldCheck = ""
		//for (i = 0; i < 5 * nNumOfPeaks + 1; i += 1)
		//	sTHoldCheck += "1"
		//endfor
			
		duplicate /O $(NameOfWave(wCoefWave)), $(NameOfWave(wCoefWave)+"S")
		wave wCoefWaveS = $(NameOfWave(wCoefWave)+"S")

		//print sHoldcheck
		//abort
		//print wCoefWaveS
		FuncFit /C /Q=1/H=sHoldcheck /NTHR=0 XPS_1GLAs,wCoefWaveS, wTmpData[lp,rp] /D /C = wConstrainWave /STRC = s // do fake fit to create constrain matrix and wave
		
//		FuncFit/Q=1/H=sHoldcheck /NTHR=0 XPS_1GLAs,$sCoefWave, wTraceName[lp,rp] /D /C = $sConstrainWave /STRC = fs// DO FIT!!!
		
		
		//print wTmpData[112], sHoldcheck, wCoefWaveS, wConstrainWave
		
		//abort
		wCoefWaveS = wCoefWave
		silent 0
		//abort
		//print nNumOfThreadsnNumOfThreadsnNumOfThreads
		nNumOfThreads = 1
		for (nThreadCount = 0; nThreadCount < nNumOfThreads; nThreadCount += 1) 
			nNumGraphsThread = floor(nNumGraphTot / nNumOfThreads) // idealized number of graphs per thread
			nNumGraphsThread = nThreadCount == nNumOfThreads - 1 ? (nNumGraphTot - nThreadCount * nNumGraphsThread) : nNumGraphsThread
			t = round(nNumGraphTot / nNumOfThreads)
			make /O/N = (DimSize($sListOfGraphs,0),nNumGraphsThread) $(sListOfGraphs + "T" + num2str(nThreadCount)) // graphs to fit in current thread
			make /O/N = (nNumOfPeaks * 5 + 1,nNumGraphsThread) $("Coef2D_" + sListOfGraphs + "T" + num2str(nThreadCount)) // wave for collections of fit coefs
			
			wave wListOfGraphsThread = $(sListOfGraphs + "T" + num2str(nThreadCount))
			wave wCoef2DWave = $("Coef2D_" + sListOfGraphs + "T" + num2str(nThreadCount))
			wCoef2DWave = 0
			
			for (i = 0; i <  nNumGraphsThread; i += 1)
				for (j = 0; j <  DimSize($sListOfGraphs,0); j += 1)
					wListOfGraphsThread [j][i] = wListOfGraphs [j][ nThreadCount * t  + i] // fill data wave with data
				endfor
			endfor
						
			duplicate /O $("Coef_" + sListOfGraphs ) $("Coef_" + sListOfGraphs + "T" + num2str(nThreadCount))
			duplicate /O $("Link_" + sListOfGraphs ) $("Link_" + sListOfGraphs + "T" + num2str(nThreadCount))
			duplicate /O $("LinkV_" + sListOfGraphs ) $("LinkV_" + sListOfGraphs + "T" + num2str(nThreadCount))
			duplicate /O $("Hold_" + sListOfGraphs ) $("Hold_" + sListOfGraphs + "T" + num2str(nThreadCount))
			duplicate  /O $("Use_" + sListOfGraphs ) $("Use_" + sListOfGraphs + "T" + num2str(nThreadCount))
			duplicate  /O $("MinC_" + sListOfGraphs ) $("MinC_" + sListOfGraphs + "T" + num2str(nThreadCount))
			duplicate  /O $("MaxC_" + sListOfGraphs ) $("MaxC_" + sListOfGraphs + "T" + num2str(nThreadCount))
			
			wave wCoefWave = $("Coef_" + sListOfGraphs + "T" + num2str(nThreadCount))
			wave wLinkWave = $("Link_" + sListOfGraphs + "T" + num2str(nThreadCount))
			wave wLinkVWave = $("LinkV_" + sListOfGraphs + "T" + num2str(nThreadCount))
			wave wHoldWave = $("Hold_" + sListOfGraphs + "T" + num2str(nThreadCount))
			wave wUseWave = $("Use_" + sListOfGraphs + "T" + num2str(nThreadCount))
			wave wMinCWave = $("MinC_" + sListOfGraphs + "T" + num2str(nThreadCount))
			wave wMaxCWave = $("MaxC_" + sListOfGraphs + "T" + num2str(nThreadCount))
			
			duplicate /O $(NameOfWave(wCoefWave)), $(NameOfWave(wCoefWave)+"S")
			wave wCoefWaveS = $(NameOfWave(wCoefWave)+"S")
				
			duplicate /O $("M_FitConstraint") $("M_FitConstraint" +  num2str(nThreadCount))
			wave M_FitConstraint = $("M_FitConstraint" +  num2str(nThreadCount)) // constrain matrix
			duplicate /O $("W_FitConstraint") $("W_FitConstraint" +  num2str(nThreadCount))
			wave W_FitConstraint = $("W_FitConstraint" + num2str(nThreadCount))	// constrain wave
			
			make /O/N = (nDimSize) $(sListOfGraphs + "_FW" + num2str(nThreadCount) ) // one dimentional wave  for current fit
			setScale x,  DimOffset(wListOfGraphs,0), nDimSize * DimDelta (wListOfGraphs,0) +  DimOffset(wListOfGraphs,0), $(sListOfGraphs + "_FW" + num2str(nThreadCount) )
			wave wFW = $(sListOfGraphs + "_FW" + num2str(nThreadCount) )
	
			//ThreadStart threadGroup, nThreadCount, somef(sHoldcheck, wCoefWave,wListOfGraphsThread, M_FitConstraint, W_FitConstraint, wLinkWave, wLinkVWave, CursorNames, nNumOfPeaks) // this is test function
			
			//Main fit thread:
			
			
			//abort
			ThreadStart threadGroup, nThreadCount, DoMultiFitFunc(nThreadCount,round(nNumGraphTot / nNumOfThreads),wListOfGraphsThread, wCoef2DWave, wCoefWave, wCoefWaveS, wLinkWave, wLinkVWave, wMinCWave, wMaxCWave, sHoldcheck, lp,rp,M_FitConstraint, W_FitConstraint, wFW, CursorNames, nNumOfPeaks, wAreaWave  )
		
		endfor

		do // here check whether the fit is done
			print datetime - nTime0 , "s, still running"
		while (ThreadGroupWait(threadGroup, 1000))
		
		if (ThreadGroupRelease(threadGroup) == -2)
			print "Force quit, estart Igor Pro"
		endif
		
		print "Fit Done"
		print "Begin transferring data.", num2str(nNumOfThreads), "transfers. " 
		//abort
		nNumGraphsThread = round(nNumGraphTot / nNumOfThreads) 
		
		//copy fit data from threads into stanrard coefwaves
		for (nThreadCount = 0; nThreadCount < nNumOfThreads; nThreadCount += 1) 
			
			wave wCoef2DWave = $("Coef2D_" + sListOfGraphs + "T" + num2str(nThreadCount))
			
			for (idx = 0; idx < DimSize(wCoef2DWave,1); idx += 1)
				if (n2DType)
					make /O /N = (DimSize(wCoef2DWave,0)) $("Coef_" + sListOfGraphs + "_" + num2str( nThreadCount *nNumGraphsThread + idx + 1))
					duplicate $(NameOfWave(wLinkWave)) $("Link_" + sListOfGraphs + "_"+ num2str( nThreadCount * nNumGraphsThread + idx + 1))
					duplicate $(NameOfWave(wLinkVWave)) $("LinkV_" + sListOfGraphs + "_"+ num2str( nThreadCount * nNumGraphsThread + idx + 1))
					duplicate $(NameOfWave(wHoldWave)) $("Hold_" + sListOfGraphs + "_"+ num2str( nThreadCount * nNumGraphsThread + idx + 1))
					duplicate $(NameOfWave(wUseWave)) $("Use_" + sListOfGraphs + "_"+ num2str( nThreadCount * nNumGraphsThread + idx + 1))
					duplicate $(NameOfWave(wMinCWave)) $("MinC_" + sListOfGraphs + "_"+ num2str( nThreadCount * nNumGraphsThread + idx + 1))
					duplicate $(NameOfWave(wMaxCWave)) $("MaxC_" + sListOfGraphs + "_"+ num2str( nThreadCount * nNumGraphsThread + idx + 1))
					wave w =$("Coef_" + sListOfGraphs + "_" + num2str( nThreadCount * nNumGraphsThread + idx + 1))
					wave wL = $("Link_" + sListOfGraphs + "_" + num2str( nThreadCount * nNumGraphsThread + idx + 1))
					wave wLV =  $("LinkV_" + sListOfGraphs + "_" + num2str( nThreadCount * nNumGraphsThread + idx + 1))			
					wave wHold =  $("Hold_" + sListOfGraphs + "_" + num2str( nThreadCount * nNumGraphsThread + idx + 1))			
					wave wUse =  $("Use_" + sListOfGraphs + "_" + num2str( nThreadCount * nNumGraphsThread + idx + 1))				
					wave wMinC =  $("MinC_" + sListOfGraphs + "_" + num2str( nThreadCount * nNumGraphsThread + idx + 1))				
					wave wMaxC =  $("MaxC_" + sListOfGraphs + "_" + num2str( nThreadCount * nNumGraphsThread + idx + 1))				
				else
					make /O /N = (DimSize(wCoef2DWave,0)) $("Coef_" + stringFromList( nThreadCount *nNumGraphsThread + idx, sListOfWaves))
					duplicate /O $(NameOfWave(wLinkWave)) $("Link_" + stringFromList( nThreadCount *nNumGraphsThread + idx, sListOfWaves))
					duplicate /O $(NameOfWave(wLinkVWave)) $("LinkV_" + stringFromList( nThreadCount *nNumGraphsThread + idx, sListOfWaves))
					duplicate /O $(NameOfWave(wHoldWave)) $("Hold_" + stringFromList( nThreadCount *nNumGraphsThread + idx, sListOfWaves))
					duplicate /O $(NameOfWave(wUseWave)) $("Use_" + stringFromList( nThreadCount *nNumGraphsThread + idx, sListOfWaves))
					duplicate /O $(NameOfWave(wMinCWave)) $("MinC_" + stringFromList( nThreadCount *nNumGraphsThread + idx, sListOfWaves))
					duplicate /O $(NameOfWave(wMaxCWave)) $("MaxC_" + stringFromList( nThreadCount *nNumGraphsThread + idx, sListOfWaves))
					wave w =$("Coef_" + stringFromList( nThreadCount *nNumGraphsThread + idx, sListOfWaves))
					wave wL = $("Link_" + stringFromList( nThreadCount *nNumGraphsThread + idx, sListOfWaves))
					wave wLV =  $("LinkV_" +  stringFromList( nThreadCount *nNumGraphsThread + idx, sListOfWaves))	
					wave wHold =  $("Hold_" +  stringFromList( nThreadCount *nNumGraphsThread + idx, sListOfWaves))	
					wave wUse =  $("Use_" +  stringFromList( nThreadCount *nNumGraphsThread + idx, sListOfWaves))	
					wave wMinC =  $("MinC_" +  stringFromList( nThreadCount *nNumGraphsThread + idx, sListOfWaves))	
					wave wMaxC =  $("MaxC_" +  stringFromList( nThreadCount *nNumGraphsThread + idx, sListOfWaves))				
				endif
				
				for (i = 0; i < DimSize(wCoef2DWave,0); i += 1)
					w[i] = wCoef2DWave[i][idx]
				endfor
			
				
				SaveCoefWave(NameOfWave(w))
			endfor
			
			Print "transfer", nThreadCount + 1, "completed"
			KillWaves $("Link_" + sListOfGraphs + "T" + num2str(nThreadCount))
			KillWaves $("LinkV_" + sListOfGraphs + "T" + num2str(nThreadCount))
			KillWaves $("Hold_" + sListOfGraphs + "T" + num2str(nThreadCount))
			KillWaves $("Use_" + sListOfGraphs + "T" + num2str(nThreadCount))
			KillWaves $("MinC_" + sListOfGraphs + "T" + num2str(nThreadCount))
			KillWaves $("MaxC_" + sListOfGraphs + "T" + num2str(nThreadCount))
			KillWaves  $(sListOfGraphs + "_FW" + num2str(nThreadCount) ) 
			KillWaves $("Coef2D_" + sListOfGraphs + "T" + num2str(nThreadCount)) // kill 2D coef wave
			KillWaves $("Coef_" + sListOfGraphs + "T" + num2str(nThreadCount)) // kill 1D coef wave
			KillWaves $("Coef_" + sListOfGraphs + "T" + num2str(nThreadCount) + "S") // kill 1D spare wave
			KillWaves $(sListOfGraphs + "T" + num2str(nThreadCount)) // kill 2D data wave
			KillWaves $("M_FitConstraint" +  num2str(nThreadCount)) // kill constraint matrix
			KillWaves $("W_FitConstraint" +  num2str(nThreadCount)) // kill constraint vertor
	
		endfor
		Killwaves $(NameOfWave(wTmpData))
		KillWaves $("Coef_" + sListOfGraphs )
		KillWaves $("Coef_" + sListOfGraphs + "S" )
		KillWaves $("Link_" + sListOfGraphs )
		KillWaves $("LinkV_" + sListOfGraphs) 
		KillWaves $("Hold_" + sListOfGraphs) 
		KillWaves $("Use_" + sListOfGraphs) 
		KillWaves $("MinC_" + sListOfGraphs )
		KillWaves $("MaxC_" + sListOfGraphs )
		if (!n2DType)
			if (!IsImagePlotted(StringFromList(0,sListOfGraphs)))
				KillWaves $sListOfGraphs
			endif
		endif
		
		print "Finish transfering fit data"
		Print "complete all in", datetime - nTime0, "s"
		SetdataFolder sCurDF
		
	
end

threadsafe function somef(sHoldcheck, wCoefWave,wTmpData,M_FitConstraint, W_FitConstraint, wLinkWave, wLinkWaveV, CursorNames, nNumOfPeaks)
	string sHoldcheck
	wave wTmpData, M_FitConstraint, W_FitConstraint, wCoefWave, wLinkWave, wLinkWaveV
	wave /T CursorNames
	variable nNumOfPeaks

	print "fit start"
	STRUCT stFitFuncStruct fs
	wave fs.wCurLinks = wLinkWave
	wave fs.wCurLinkVs = wLinkWaveV
	wave /t fs.CursorNames = CursorNames
	fs.nNumOfPeaks = nNumOfPeaks
	//print fs.wCurLinks, fs.wCurLinkVs, fs.CursorNames, wCoefWave, wTmpData, M_FitConstraint, W_FitConstraint, sHoldcheck
	
	FuncFit/Q=1/H=sHoldcheck  XPS_1GLAs,wCoefWave, wTmpData /D /C = {M_FitConstraint, W_FitConstraint} /STRC = fs// DO FIT!!!
	print wCoefWave[1]
	print "fitdone"
	
end


ThreadSafe function DoMultiFitFunc (nThreadCount,nThreadWidth,wListOfGraphs, wCoef2DWave, wCoefWave, wCoefWaveS, wLinkWave, wLinkVWave, wMinCWave, wMaxCWave, sHoldcheck, lp,rp,M_FitConstraint, W_FitConstraint,  wtmpwave,CursorNames, nNumOfPeaks, wAreaWave)
	variable nThreadCount // thread id
	variable nThreadWidth // idealized width of the thread
	wave wListOfGraphs // 2D wave containing all spectra to fint in current thread
	wave wCoef2DWave // 2D wave to collect results of the fit
	wave wCoefWave // current coefficient wave
	wave wCoefWaveS // spare coef wave with initial coefs 
	wave wLinkWave // current link wave
	wave wLinkVWave // current linkV wave
	wave wMinCWave
	wave wMaxCWave
	wave M_FitConstraint // constraint matrix
	wave W_FitConstraint // constraint wave
	wave wtmpwave // current spectrum to fit
	string sHoldcheck // hold string
	variable lp,rp // left and right BE borders for fit
	wave /T CursorNames // cursor names wave
	variable nNumOfPeaks // number of fit peaks
	wave wAreaWave

	string sListOfGraphs = NameOfWave (wListOfGraphs)
	variable idx,i
	variable nNumOfGraphs = DimSize (wListOfGraphs, 1)
	variable nDimSize =  DimSize (wListOfGraphs, 0)
	variable t = 0
	variable V_FitError = 0
	variable V_FitQuitReason = 0
	
	
	
	
	
	for (idx = 0; idx < nNumOfGraphs; idx += 1)	
		for (i = 0; i < DimSize(wListOfGraphs, 0); i += 1) // fill 1D wave with data from 2D wave
			wtmpwave[i] = wListOfGraphs[i][idx] 
		endfor
			
		//Create a structure 
		STRUCT stFitFuncStruct fs 
		wave fs.wCurLinks = wLinkWave
		wave fs.wCurLinkVs = wLinkVWave
		wave fs.wMinC = wMinCWave
		wave fs.wMaxC = wMaxCWave
		wave /t fs.CursorNames = CursorNames
		wave fs.wGLAsArea = wAreaWave
		
		fs.nNumOfPeaks = nNumOfPeaks
		V_FitError = 0
		V_FitQuitReason = 0


		//print nameofwave(wCoefWave), nameofwave(wtmpwave)





		FuncFit/Q=1/H=sHoldcheck /NTHR=0 XPS_1GLAs,wCoefWave, wtmpwave[lp,rp] /D /C = {M_FitConstraint, W_FitConstraint} /STRC = fs // DO FIT!!!
	//print sHoldcheck, wCoefWave
		
		if (GetBit(1,V_FitError) ) // if singular matrix error
			//sErr = ""
			print "Error in wave:", nThreadWidth * nThreadCount + idx + 1 , ", reason: Singular Matrix error. Trying refit "
			V_FitError = 0
			FuncFit/Q=1/H=sHoldcheck /NTHR=0 XPS_1GLAs,wCoefWave, wtmpwave[lp,rp] /D /C = {M_FitConstraint, W_FitConstraint} /STRC = fs // refit once
			if (GetBit(1, V_FitError))
				print "Refit for wave" , nThreadWidth * nThreadCount + idx + 1 , "unseccessful"
			else
				print "Refit for wave", nThreadWidth * nThreadCount + idx + 1 , "successful"
			endif
		endif
		if (GetBit(3,V_FitError) ) // if function returning NaN or Inf error
			print "Error in wave:", nThreadWidth * nThreadCount + idx + 1 , ", reason: Function returned NaN or INF. Trying refit "
			V_FitError = 0
			wCoefWave = wCoefWaveS // reset coef wave
			FuncFit/Q=1/H=sHoldcheck /NTHR=0 XPS_1GLAs,wCoefWave, wtmpwave[lp,rp] /D /C = {M_FitConstraint, W_FitConstraint} /STRC = fs // refit once
			if (GetBit(3, V_FitError))
				print "Refit for wave", nThreadWidth * nThreadCount + idx + 1 ," unseccessful"
			else
				print "Refit for wave", nThreadWidth * nThreadCount + idx + 1 , "successful"
			endif
		endif
			
		for (i = 0; i < 5 * nNumOfPeaks + 1; i += 1)
			wCoef2DWave[i][idx] = wCoefWave[i]
		endfor
	
	endfor
	
	
end
		
threadsafe function GetBit(nBitNum, nDecNum)
	variable nDecNum, nBitNum
	
	variable i = 0
	for (i = 0; i < nBitNum;  i += 1)
		nDecNum = trunc(nDecNum / 2)	
	endfor
	return mod (nDecNum,2)
end
//_____________________________________________

function IsImagePlotted(sWaveName) 
	String sWaveName
	
	string sListOfWins = WinList("*", ";","")
	variable i = 0
	variable nIsPlotted = 0
	for (i = 0; i < ItemsinList(sListOfWins); i += 1)
		//print StringFromList(i,sListOfWins), ImageNameList(StringFromList(i,sListOfWins), ";")
		if (strsearch((ImageNameList(StringFromList(i,sListOfWins), ";")),sWaveName,0) != -1 )
			nIsPlotted = 1
		endif
	endfor
	return nIsPlotted
end


//_________________________________________________
function PrintPeakAreas(ctrlName)
	string ctrlName
	
	//print "go"
	string sCurFolder = GoToDataFolder()
	string sListOfWaves = TraceNameList ("", ";", 1) // get list of all waves on the graph
	wave wWave = $StringFromList(0,sListOfWaves) // get first wave on the graph
	
	if (!WaveExists(wWave))
		wave wWave = ImageNameToWaveRef ("", StringFromList(0,ImageNameList("",";")))
	endif
	
	variable nLowBE = 0
	variable nHighBE = 0
	
	variable nLBE = rightx ($NameOfWave(wWave))
	variable nHBE = leftx ($NameOfWave(wWave))
	if (nLBE > nHBE)
		variable ni = nHBE
		nHBE = nLBE
		nLBE = ni
	endif
	
	if (WaveExists(CsrWaveRef(A))) //  if A on the graph
		nLowBE = xcsr(A)
	else // if A not on the graph
		nLowBE = rightx ($NameOfWave(wWave))
	endif
	
	if (WaveExists(CsrWaveRef(B))) //  if B on the graph
		nHighBE = xcsr(B)
	else // if B not on the graph
		nHighBE = leftx ($NameOfWave(wWave))
	endif
	
	if (nLowBE > nHighBE)
		variable nint = nHighBE
		nHighBE = nLowBE
		nLowBE = nint
	endif
	
	//print nLowBE,nHighBE
	variable idx = 0
	variable i = 0
	string sWave = ""
	
	if (DimSize(wWave,1)) // if 2-dimensional wave
		Make /O/N = (DimSize(wWave,0)) wTempWave
		wave wTempWave = $("wTempWave")
		setScale x,  DimOffset(wWave,0), DimSize (wWave,0) * DimDelta (wWave,0) +  DimOffset(wWave,0), $("wTempWave") // and rescale it 
		wave wTempWave = $("wTempWave")
		
		for (i = 0; i < DimSize(wWave,1); i += 1)
			for (idx = 0; idx < DimSize(wWave,0); idx += 1)
				wTempWave[idx] = wWave[idx][i]
			endfor	
			print "area of", (NameOfWave(wWave) + "_" + num2str(i + 1)), ":", area($("wTempWave"),nLowBE,nHighBE)
		endfor
	else // is one-dimensional wave
		do
			sWave = NameOfWave(wWave)
			//if (stringmatch(sWave[strlen(sWave)-2], "_") == 1 || stringmatch(sWave[strlen(sWave)-3], "_") == 1 || stringmatch(sWave[0,3], "fit_"))
			//	print "area of", sWave, "[", nLBE, ",", nHBE, "]:", area(wWave,nLBE,nHBE)
			//else
				print "area of", sWave, "[", nLowBE, ",", nHighBE, "]:", area(wWave,nLowBE,nHighBE)
				print "area of", sWave, "[", nLBE, ",", nHBE, "]:", area(wWave,nLBE,nHBE)
			//endif
			idx += 1
			wave /Z wWave = $StringFromList(idx,sListOfWaves) /// get wave
		while (WaveExists(wWave))
	endif
	
	
	SetDataFolder sCurFolder
end
//__________________________________________________
//function NormByArea ()
	
//	string sDF = GotoDataFolder()
//	string sListOfWaves = TraceNameList ("",";",1) // get list of all waves
//	wave/Z wCoefWave = $("wCoef2DWave")
//	variable i = 0, j = 0
//	variable nArea = 0
	
//	variable nLowBE = 0
//	variable nHighBE = 0
	
	
	
//	for (i = 0; i < ItemsInList(sListOfWaves); i += 1)
//		wave wWave = $(StringFromList(i, sListOfWaves))
		
//		if (WaveExists(CsrWaveRef(A))) //  if A on the graph
//			nLowBE = xcsr(A)
//		else // if A not on the graph
//			nLowBE = rightx ($NameOfWave(wWave))
//		endif
	
//		if (WaveExists(CsrWaveRef(B))) //  if B on the graph
//			nHighBE = xcsr(B)
//		else // if B not on the graph
//			nHighBE = leftx ($NameOfWave(wWave))
//		endif
	
//		if (nLowBE > nHighBE)
//			variable nint = nHighBE
//			nHighBE = nLowBE
//			nLowBE = nint
//		endif
		
//		nArea =  area(wWave,nLowBE,nHighBE)
//		wWave /= nArea
//		if (WaveExists(wCoefWave))
//			variable nPlace = FindStrInWave(("Coef_" + StringFromList(i,sListOfWaves)), $("wCoefNamesWave"))
//			if (nPlace != -1) // if coef exists
//				for (j = 1; j < 61; j += 5)
//					wCoefWave[j][nPlace][0] /= nArea
//				endfor
//			endif
//		endif
//	endfor
	
//	SetDataFolder sDF
//end
//___________________________________________________

function XPS_FitD_Migrate()
 	
 	string sCurDataFolder = GetDataFOlder(1)
 	SetDataFolder root:
 	string sListDataFolders = DataFOlderDir(1)
 	string sFName = "root:"
 	variable idx = 0, i,j
 	nvar /Z gnUpToAreas = root:XPS_Fit_dialog:g_nUpToAreas
 	variable nUpToAreas
 	if (nvar_Exists(gnUpToAreas) && gnUpToAreas == 1)
 		nUpToAreas = 1
 	else
 		variable /g root:XPS_Fit_dialog:g_nUpToAreas = 1
 		nUpToAreas = 0
 	endif
 	
 	
 	do
 		
 		if (strlen (sFName) == 0)
 			break
 		endif
 		if (!stringmatch(sFName,"XPS_QuickFileViewer") && !stringmatch (sFName, "Quick_File_Viewer"))
 			SetDataFolder $sFName
 			
 			//****************** Save coefficient waves into Wave2Dwave ***********************
 			
 			if (strlen(WaveList("coef_*", ";", "")) != 0)
 				String sListOfWaves = WaveList("coef_*",";", "")
 				String sWName 
 				for (i = 0; i < ItemsInList(sListOfWaves); i += 1)
 					sWName = StringFromList(i,sListOfWaves )
 					SaveCoefWave(sWName)
 					endfor
 			endif 	
 		
 			//******************** Convert intensities into areas *************************
 			
 			if (!nUpToAreas) 
 				Load2DAreaWave()
				wave wAreaWave = AreaWave	
				 				
 				if (waveexists(wCoefNamesWave))
 					wave/T w = wCoefNamesWave
 					for (i = 0; i < dimsize(w,0); i += 1)
 						wave /Z wW = GetCoefWave(w[i])
 						if (waveExists(wW))
 							for (j = 1; j< DimSize (wW,0); j += 5)
 								//print Nameofwave(wW), wW[j], wW[j+1], wW[j+2], wW[j+3]
 								wW[j] *= wW[j+2] * (wAreaWave(wW[j+4])( wW[j+3]))
 								
 							endfor
 						SaveCoefWave(NameOfWave(wW))
 						endif
 					endfor
 					
 					
 				endif
 			endif
 			
 			
 			
 			
 			
 			
 			//***************** Convert link and linkv waves into 3D wave *********************
 			
 			//print "hehehe"
 			print GetDataFolder(1)
 			wave /Z wCoef2DWave = $("wCoef2DWave")
			wave /Z wLink2DWave = $("wLink2DWave")
		 	wave /Z wLinkV2DWave = $("wLinkV2DWave")
 			wave /Z wCoefNamesWave = $("wCoefNamesWave")			
			
 	
 			print WaveExists(wCoef2DWave)// && WaveExists(wCoefNamesWave) && WaveExists(wLink2DWave) && WaveExists(wLinkNamesWave) && WaveExists(wLinkV2DWave) && WaveExists(wLinkVNamesWave))
 			
 			if (WaveExists(wCoef2DWave) && WaveExists(wCoefNamesWave) && WaveExists(wLink2DWave) && WaveExists(wLinkNamesWave) && WaveExists(wLinkV2DWave) && WaveExists(wLinkVNamesWave))
 				Redimension /N = (DimSize (wCoef2DWave,0), DimSize(wCoef2DWave,1),5) wCoef2DWave

 				for (i = 0; i < DimSize (wCoef2DWave,1); i += 1)
 					for (j = 0; j < DimSize(wCoef2DWave,0); j += 1)
 						wCoef2DWave [j][i][1]= wLink2DWave[j][i] 
 						wCoef2DWave [j][i][2]= wLinkV2DWave[j][i]
 						wCoef2DWave [j][i][3]= 0
 						wCoef2DWave [j][i][4]= 0
 						wCoef2DWave [j][i][5]=0
 						wCoef2DWave [j][i][6]= 0
 					endfor
 				endfor
 			
 				KIllwaves $NameOfWave (wLink2DWave)
 				KIllwaves $NameOfWave (wLinkV2DWave)
 				KillWaves $("wLinkNamesWave")
 				KillWaves $("wLinkVNamesWave") 			
 			endif			
 		
 			SetDataFolder root:
 			
 			//***************************************
 		endif
 		idx += 1
 		sFName = GetIndexedObjName(":", 4, idx)
 	while (1)
 	SetDataFolder $sCurDataFolder
end

//__________________________________________________


function Load2DAreaWave()
	
	newpath /o pPath ,":User Procedures"
	LoadWave /O/M /G /P=pPath /B="N=AreaWave;" "ntable.txt" 
	setscale X 0,1, AreaWave
	setscale Y 0,1, AreaWave
	
end
