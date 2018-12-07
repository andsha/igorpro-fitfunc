// 		XPS quick file view dialog V 2.2.9
// 		20 - Feb - 2013
//		version 2.2.1 issued on 2011-11-05
//		Developed by Andrey Shavorskiy, Georg Held, Achim Schnadt
//
//		2011-11-09	Added function for image averaging; some small bugs are fixed
//		2011-11-17	Result of multi wave analysis is displayed
//		2011-12-11	Added Igor text load


#pragma rtGlobals=1		// Use modern global access method.
#include <FITS Loader>


constant GENERALTEXT = 1
//constant GENERALTEXTMATRIX = 2
constant IGORTEXT=3
//constant IGORTEXTMATRIX = 4
constant IGORBINARY = 5
constant SPECSXY = 6
constant SPECSXML = 7
constant NEXAFS1D = 8
constant NEXAFSFITS = 9
constant IGOREXP = 10

constant NOBACK = 100
constant SHIRLEY = 101
constant LINEAR = 102
constant SUBBACK = 103
constant DIVBACK = 104

constant ARITHM_NORMAREAS = 201
constant ARITHM_AVERAGE = 202
constant ARITHM_SUM = 203
constant ARITHM_BINHOR = 204
constant ARITHM_BINVER = 205
constant ARITHM_PLUSB = 206
constant ARITHM_MINUSB = 207
constant ARITHM_MULTB = 208
constant ARITHM_DIVB = 209
constant ARITHM_PLUSC = 210
constant ARITHM_MINUSC = 211
constant ARITHM_MULTC = 212
constant ARITHM_DIVC = 213
constant ARITHM_BEPLUS = 214
constant ARITHM_BEMINUS = 215
constant ARITHM_ETOBE = 216
constant ARITHM_ATOBSHIFT = 217

constant MODE_EDGES = 301
constant MODE_RUNAVG = 302
constant MODE_KE = 303
constant MODE_BE = 304

constant CMODE_C = 1001
constant CMODE_CPS = 1002

constant GETAREA_TOTAL = 2001
constant GETAREA_NOSHIRLEY = 2002
constant GETAREA_NOLINEAR = 2003
constant GETAREA_BTWCSRS = 2004

constant QICKFILEVIEWER_PANELHEIGHT = 500
	

function XPS_quick_file_viewer()
end

Menu  "XPS"
	"-"
	"File viewer...", QuickFileViewer() 
	"Fit single wave...", FitPanel (0)
	Submenu "Various"
		//"Set trace colours", XPS_SetRainbowColours ()
		"Save Specs spectra...", SaveSpecsWaves()
		"Make linear temp...", MakeLinTemp()
		"Rename waves...", ReNameList ("","")
		"Norm Scienta Sweeps", XPSFit_ScientaSweepFunc()
		//"Show Matrix traces", XPSFit_ShowMatrixTraces()
		
	end
	"-", 
	"Settings...", SetXPSQFWParameters()
	
end

//  function Create_QuickFileViewr_Globals()
// create folder with auxilary waves and variables to permanently keep dialog data
function Create_QuickFileViewr_Globals()
	
	SVAR /Z  sViewerVersion = root:XPS_QuickFileViewer:g_sViewerVersion
	String sLatestVersion = "2.2.28"
	if (!SVAR_Exists(sViewerVersion) || (SVAR_Exists(sViewerVersion) && !stringmatch(sViewerVersion, sLatestVersion)))
		print "update to version", sLatestVersion
		XPS_QuickViewer_Update()
	else
		if (DataFOlderExists("root:XPS_QuickFileViewer"))
			return 0
		endif
	endif
	
	String sCurrDataFolder = GetDataFolder(1)
	SetDataFolder $("root:")
	NewDataFolder /O $("XPS_QuickFileViewer")
	SetDataFolder $("XPS_QuickFileViewer")
	
	String/G g_sViewerVersion = sLatestVersion
	variable bLoad = 0

	if (XPSFit_LoadGlobals()  == 0 && stringmatch(g_sViewerVersion, sLatestVersion) )
		bLoad = 1
	else
		g_sViewerVersion = sLatestVersion
	endif
	
	Make/O/T/N = 10 wCursNames
	Wave/T wCursNames = $("wCursnames")
		wCursNames[0] = "A"
		wCursNames[1] = "B"
		wCursNames[2] = "C"
		wCursNames[3] = "D"
		wCursNames[4] = "E"
		wCursNames[5] = "F"
		wCursNames[6] = "G"
		wCursNames[7] = "H"
		wCursNames[8] = "I"
		wCursNames[9] = "J"
		
	Variable i
	
	String /G sLoadMenuList = "XPS Auto;General Text;Igor Text;Igor Binary;Specs XML, XY;Igor experiment;FITS NEXAFS;NEXAFS 1D" 
	
	String /G 		sRemoveWaves = "all except visible;partially visible;fully visible"
	String /G 		sMakeView = "Fully organized;Spread;"
	string /G 		sColourScheme = "Rainbow;Inversed Rainbow;RBBGY;"
	string /G		g_sGetArea = "Total;No back, between csrs;No Shirley back;No linear back;"
	String /G 		sBin1D = "2;4;8;16;32;64;128;256;512;"
	string /G		sBinMode = "Edges;RunAvg;"
	Variable /G 	n_ButtonSize = 40 
	Variable /G 	n_ButtonHeight = 25 
	Variable /G 	n_InterCtrlDis = 5// distance between buttons
	Variable /G 	n_BtnsRow = 2 // number of Buttons in a row
	String /G 		g_sButtonTextFont = "\Z10"
	
	variable /G 	g_nWWidth,g_nWHeigth
	
	
	String /G  		g_NamePrefix = "X_"
	Variable /G  	g_ColumnE
	Variable /G 	g_ColumnInt
	string /G 		g_FITSPE = "photon energy"
	Make /T/O /N=(8) $("wFITSLoadList")
	Make /O /N=(8) $("wFITSLoadSelList")
	Make /T/O /N=(8) $("wFITSNameList")
	Make /O /N=(8) $("wFITSNameSelList")
	wave 			wFITSLoadSelList 
	wFITSLoadSelList = 18
	wave 			wFITSNameSelList
	wFITSNameSelList = 18
	wave /T 		wFITSLoadList
	wave /T 		wFITSNameList
	wFITSLoadList[0] = "Fixed_Spectra"
	wFITSNameList[0] = "I"
	wFITSLoadList[1] = "ALS_I0"
	wFITSNameList[1] = "Io"
	
	
	String /G  g_XASPrefix = "N_"
	//Variable /G  g_Columnhv
	//Variable /G g_ColumnI
	
	Variable /G g_bOverWriteWave = 0 // overwrite waves while loading
	variable /G g_bKeepSwepsXML = 0 // keep individual sweeps while loading XML
	variable /G g_bDisplayWArithmRes = 0 // display result of sum and aver operations in separate window
	variable /G g_bAppendWArithmRes = 1 // append result of sum and aver operations on same graph
	variable /G g_nAverageXWidth = 0.5

	Variable /G g_nFermi 

	String /G g_sEnergyType = "Binding energy"
	String /G g_sBackType = "Linear"
	String /G g_sNormalize = "No"
	
	make /T/O /N=(1024,6) wHistory
	wHistory = "0"
	
	Variable /G g_bLoadTimeDate = 0 // no
	Variable /G g_bUseFileName = 0 // no
	String /G g_sMakeMatrixMethod = "Extend"
	
	String /G g_sSCIENTASweepStr = "Number of Sweeps"
	String /G g_sSCIENTATime = "Step Time"

	if (bLoad)
		XPSFit_LoadGlobals()
	endif
	
	
	SetDataFolder sCurrDataFolder
	
end
//__________________________________________________________________

// function QuickFileViewer() 
// create and display dialog for fast  data loading and manipulation
function QuickFileViewer()
	
	Create_QuickFileViewr_Globals()
	
	if (strlen(WinList("Quick_File_Viewer",";","")))
		DoWindow /F $("Quick_File_Viewer")
		return 0
	endif
	
	String /G 		root:XPS_QuickFileViewer:g_sDataFolderPath 
	SVAR sDataFolderPath = root:XPS_QuickFileViewer:g_sDataFolderPath
	getfilefolderinfo /D/Q 
	sDataFolderPath = s_path
	newpath /O sPath sDataFolderPath
	
	String 	sListOfFiles = IndexedFile(sPath, -1,"????")
	Variable 	nNumOfFiles = ItemsInList(sListOfFiles)
	Make /O/T/N=(nNumOfFiles) root:XPS_QuickFileViewer:wListOfFiles
	Wave/T 	wListOfFiles = $("root:XPS_QuickFileViewer:wListOfFiles")
	Make /O/N=(nNumOfFiles) root:XPS_QuickFileViewer:wListOfSelFiles
	Wave wListOfSelFiles = $("root:XPS_QuickFileViewer:wListOfSelFiles")	
	wListOfSelFiles = 0
	
	variable i
	for (i = 0; i < nNumOfFiles; i += 1)
		wListOfFiles[i]= StringFromList(i,sListOfFiles)
	endfor
	
	NVAR 		nButtonSize = root:XPS_QuickFileViewer:n_ButtonSize
	NVAR 		nBH =  root:XPS_QuickFileViewer:n_ButtonHeight 
	NVAR 		nInterCtrlDis = root:XPS_QuickFileViewer:n_InterCtrlDis
	SVAR 		sBtnFont = root:XPS_QuickFileViewer:g_sButtonTextFont
	NVAR 		bDisplayWArithmRes = root:XPS_QuickFileViewer:g_bDisplayWArithmRes
	NVAR 		bAppendWArithmRes = root:XPS_QuickFileViewer:g_bAppendWArithmRes
	
	NVAR 		nWWidth =  root:XPS_QuickFileViewer:g_nWWidth
	NVAR 		nWHeigth = root:XPS_QuickFileViewer:g_nWHeigth
	
	Variable 	left = 400 + enoise (400)
	Variable 	top = 100 + enoise (100)
	Variable 	width = 250
	Variable 	nAddBtnsHeight = 20;
	nAddBtnsHeight += 3 * nInterCtrlDis
	variable 	nBigButtonHeight = 40 
	Variable 	height =  QICKFILEVIEWER_PANELHEIGHT
	variable 	nListBoxHeight = height-85
	nWWidth = width
	nWHeigth = height
	
	
	NewPanel /K=1/W = (left,top, left + width, top + height) /N=$("Quick_File_Viewer")
	SetWindow $("Quick_File_Viewer") hook = XPSFit_QFVHook
	
	
	TabControl XPSFit_Viewer, pos = {0,5}, size = {width, 17}, tablabel(0) = "File Viewer"

	String spath = "root:XPS_QuickFileViewer:sLoadMenuList" 
	PopupMenu LoadMenu, title = "File Type:", pos = {5,30}, size = {150, 20}, title=" ", mode = 1, value =#spath, disable = 0
	CheckBox cbDisplay, title = "Display", pos = {60,52}, value = 1,disable = 0
	Button LoadFile, title = sBtnFont + "Load", pos = {5, 50 }, size = {50,nbh}, proc = XPSFit_LoadFile, disable = 0
	Button ChangeDir, title = sBtnFont + "\Z16\F'Wingdings'1", pos = {160, 50}, size = {40,nbh}, proc = XPS_ChangeDir, disable = 0
	Button ReloadFolderContent, title = sBtnFont + "\Z16\F'Wingdings 3'Q", pos = {205, 50}, size = {30,nbh}, proc = ReloadFolderContent, title = "Re", disable = 0
	LIstBox lbListOfFiles, pos = {5, 80}, size = {width - 2 * nInterCtrlDis , nListBoxHeight},listWave = wListOfFiles, selWave = 	wListOfSelFiles
	LIstBox lbListOfFiles, mode = 10, proc = XPSFit_lbListBoxControl , disable = 0
	


	TabControl XPSFit_Viewer, pos = {0,5}, size = {width, 17}, tablabel(1) = "Wave Analysis"	, proc = XPSFit_ViewerSwitchTabs
	
	
	
	String sRemoveWaves =  "root:XPS_QuickFileViewer:sRemoveWaves" 
	String sMakeView =  "root:XPS_QuickFileViewer:sMakeView" 
	String sBin1D = "root:XPS_QuickFileViewer:sBin1D"
	string sColourScheme = "root:XPS_QuickFileViewer:sColourScheme"
	string sGetArea = "root:XPS_QuickFileViewer:g_sGetArea"
	string sBinMode = "root:XPS_QuickFileViewer:sBinMode"
	
	variable nt = 15
	nt+= 15

	Checkbox cbAppendRes, pos = {8, nt}, title ="Append results", disable = 1, value = bAppendWArithmRes, proc = XPSFit_SettingsCBSet
	Checkbox cbDisplayRes, pos = {108, nt}, title ="Display results", disable = 1, value = bDisplayWArithmRes, proc = XPSFit_SettingsCBSet
	
	nt+= nbh
	Button bnToC, pos = {8,nt}, title=sBtnFont + "To Cnts", size = {50, nbh}, proc=XPSFit_BnExe, disable = 1
	Button bnToCPS, pos = {63,nt}, title=sBtnFont + "To CPS", size = {50, nbh}, proc=XPSFit_BnExe, disable = 1
	
	nt+= nbh + 5
	Button bnBackShi,pos={8, nt },title=sBtnFont + "Back Shi", size = {50, nbh}, proc=procSubBack,  disable = 1
	Button bnBackLine,pos={63, nt },title=sBtnFont + "Back Lin", size = {50,nbh}, proc=procSubBack, disable = 1
	Button bnBackSub, title = sBtnFont + "Sub", pos = {118,nt}, size = {40,nbh}, proc = procSubBack, disable = 1
	Button bnBackDiv, title = sBtnFont + "Norm",  pos = {163,nt}, size = {40,nbh}, proc = procSubBack, disable = 1
	nt += nbh + 5
	PopUpMenu pmBackWave, mode = 1, pos = {8,nt}, value = XPSFit_GetBackWaves(), disable = 1, title = "", size = {10,50}, appearance = {native}
	nt += nbh + 5
	Button bnEToBE pos={8, nt }, size = {50,nbh}, proc=procEToBE, title=sBtnFont + "E to BE", disable = 1
	Button bnMakeFETable, pos = {63,nt}, size = {90,nbh}, proc = procMakeFETable, title = sBtnFont + "Make FE table", disable = 1
	nt+= nbh + 5
	Button bnWArithmNormAreas, title =sBtnFont + "Norm Areas", pos = {8, nt}, size = {75,nbh}, proc = WaveArithm, disable = 1
	Button bnWArithmAverWaves, title = sBtnFont + "Average", pos = {88,nt}, size = {60,nbh}, proc = WaveArithm, disable = 1
	Button bnSumWaves, title = sBtnFont + "Sum", pos = {153, nt}, size = {45,nbh}, proc = WaveArithm, disable = 1
	nt += nbh  + 5
	Button bnWArithmBinHor, title = sBtnFont + "Bin Hor", pos = {8,nt}, size = {50,nbh}, proc = WaveArithm, disable = 1
	Button bnWArithmBinVer, title = sBtnFont + "Bin Vert" , pos = {63,nt},  size = {50,nbh}, proc = WaveArithm, disable = 1
	PopupMenu pmWArithmBinSize, title = "", pos = {118,nt + 3}, size = {50, nbh}, title=" ", mode = 1, value =#sBin1D, disable = 1
	Popupmenu pmWArithmeticsBinMode, title ="", pos = {173, nt + 3}, mode = 1, value = #sBinMode, disable = 1
	
	nt+= nbh + 5
	Button SWaveArithm_APlusB, title = sBtnFont + "+ B ", pos = {8,nt}, size = {30,nbh},  proc = WaveArithm, disable = 1
	Button SWaveArithm_AMinusB, title = sBtnFont + "- B", pos = {43, nt}, size = {30,nbh}, proc = WaveArithm, disable = 1
	Button SWaveArithm_AMultB, title = sBtnFont + "* B ", pos = {78,nt}, size = {30,nbh}, proc = WaveArithm, disable = 1
	Button SWaveArithm_ADivB, title = sBtnFont + "/ B", pos = {113, nt}, size = {30,nbh}, proc = WaveArithm, disable = 1	
	nt+= nbh + 5
	Button SWaveArithm_APlusC, title = sBtnFont + "+ C",  pos = {8,nt}, size = {30,nbh}, proc = WaveArithm, disable = 1
	Button SWaveArithm_AMinusC, title = sBtnFont + "- C",  pos = {43,nt}, size = {30,nbh}, proc = WaveArithm, disable = 1
	Button SWaveArithm_AMultC, title = sBtnFont + "* C",  pos = {78,nt}, size = {30,nbh}, proc = WaveArithm, disable = 1
	Button SWaveArithm_ADivC, title = sBtnFont + "/ C",  pos = {113,nt}, size = {30,nbh}, proc = WaveArithm, disable = 1
	SetVariable SWaveArithm_C,  pos = {143,nt+5}, size = {75,30}, value = _NUM:1.02, title = " C=", disable = 1
	Button bnGetCValueFromCurs, pos = {218, nt}, size = {25,nbh}, title = sBtnFont + "Csr", proc = WaveArithmGetCFromCurs, disable = 1
	nt+= nbh + 5
	Button SWaveArithm_AToLeft, title = sBtnFont + "BE+", pos = {8,nt}, size = {50,nbh}, proc = WaveArithm, disable = 1
	SetVariable SWaveArithm_XShift, pos = {63,nt+5}, size = {53,20}, value = _NUM:0.1, disable = 1
	Button SWaveArithm_AToRight, title = sBtnFont + "BE-", pos = {120,nt}, size = {50,nbh}, proc = WaveArithm, disable = 1
	button SWaveArithm_AToBShift, title = sBtnFont + "A to B", pos = {175,nt}, size = {50,nbh}, proc = WaveArithm, disable = 1
	nt+= nbh +5
	Button WavesToMatrix pos={8,nt }, size = {65,nbh}, proc=procMakeMatrix, title=sBtnFont+"Make Matrix", help = {"Create matrix from to waves"}, disable = 1
	Button ShowWaveFromImageCursA, title = sBtnFont + "Show A",  pos =  {78,nt},  size = {45,nbh}, proc = ShowWaveFromImage, disable = 1
	Button ShowWaveFromImageCursAB, title = sBtnFont + "Show AB",  pos = {128,nt},  size = {50,nbh}, proc = ShowWaveFromImage, disable = 1
	Button ShowWaveFromImageCursAll, title = sBtnFont + "Show All",  pos = {183,nt},  size = {50,nbh}, proc = ShowWaveFromImage, disable = 1
	nt+= nbh + 5
	PopupMenu bnSetTraceColors, pos = {8,nt}, title = sBtnFont + "Set trace colors", disable = 1, proc = XPS_SetRainbowColours, value = #sColourScheme
	nt+= nbh + 5
	PopupMenu RemoveWaves, title = sBtnFont + "Remove", pos = {8,nt}, mode = 2, value = #sRemoveWaves, proc = RemoveWaves, disable = 1
	nt+= nbh + 5
	popupmenu pmGetAreaInfo, title = sBtnFont + "Get Area", pos={8,nt}, value = #sGetArea, proc = XPSFit_GetAreaProc, disable = 1
	
	nt = height - 5 - nbh
	Button bUndo, title = sBtnFont + "Undo", pos = {8, nt}, size = {30,nbh}, proc = XPS_UndoOperation, disable = 1
	//PopUpMenu MakeView, title="Make graph:", pos = {5, 415}, mode = 2, value = #sMakeView  ,proc = XPSFit_MakeView, disable = 1
	
	//GroupBox sname4, pos = {0,405}, size = {240,50}, title = "Misc", disable = 1
	
	XPS_ChangeDirFunk(0)
end
//_____________________________________________________________________
function /S XPSFit_GetBackWaves()
	return "Cursor/Original data;" + WaveList("background*",";","")
end


//
function XPSFit_QFVHook (infostr)
	string infoStr

	string sECode = StringByKey("EVENT", infoStr)
	
	NVAR nWWidth =  root:XPS_QuickFileViewer:g_nWWidth
	NVAR nWHeigth = root:XPS_QuickFileViewer:g_nWHeigth
	NVAR 	nBH =  root:XPS_QuickFileViewer:n_ButtonHeight 
	
	if (cmpstr(sECode, "resize") == 0)
		GetWindow $("Quick_File_Viewer")  wsizedc
		
		variable width = v_right - v_left
		variable height = v_bottom - v_top
		variable dY = height - nWHeigth
		
		if (width !=250 )
			GetWindow $("Quick_File_Viewer")  wsize
			MoveWindow v_left, v_top, v_left + 250, v_bottom
			
		endif
		
		if (height < QICKFILEVIEWER_PANELHEIGHT)
			GetWindow $("Quick_File_Viewer")  wsize
			MoveWindow v_left, v_top, v_right, v_top + QICKFILEVIEWER_PANELHEIGHT
			LIstBox lbListOfFiles, size = {240 , QICKFILEVIEWER_PANELHEIGHT-85  }
			Button bUndo, pos = {8,QICKFILEVIEWER_PANELHEIGHT - 5 - nbh}
			nWHeigth = QICKFILEVIEWER_PANELHEIGHT
			return 0
		endif
		
		ControlInfo lbListOfFiles
		nWHeigth = height
		LIstBox lbListOfFiles, size = {v_width , v_height + dY  }
		Button bUndo, pos = {8,height - 5 - nbh}
	endif
	
end
//___________________________________________________

function XPSFit_ViewerSwitchTabs(sName, nTab)
	string sName
	variable nTab
	
	variable top
	
	PopupMenu LoadMenu, disable = (nTab != 0)
	Button LoadFile,  disable = (nTab != 0)
	CheckBox cbDisplay, disable = (nTab != 0)
	Button ChangeDir,  disable = (nTab != 0)
	Button ReloadFolderContent,  disable = (nTab != 0)
	LIstBox lbListOfFiles,  disable = (nTab != 0)
//	Checkbox cbCsrA, disable = (nTab != 1)
//	Checkbox cbCsrB, disable = (nTab != 1)
//	Checkbox cbCsrC, disable = (nTab != 1)
//	Checkbox cbCsrD, disable = (nTab != 1)
//	Checkbox cbCsrE, disable = (nTab != 1)
//	Checkbox cbCsrF, disable = (nTab != 1)
//	Checkbox cbCsrG, disable = (nTab != 1)
//	Checkbox cbCsrH, disable = (nTab != 1)
//	Checkbox cbCsrI, disable = (nTab != 1)
//	Checkbox cbCsrJ, disable = (nTab != 1)
//	Checkbox cbCsrAll, disable = (nTab != 1)
//	titlebox tbA, disable = (nTab != 1)
//	titlebox tbB, disable = (nTab != 1)
//	titlebox tbC, disable = (nTab != 1)
//	titlebox tbD, disable = (nTab != 1)
//	titlebox tbE, disable = (nTab != 1)
//	titlebox tbF, disable = (nTab != 1)
//	titlebox tbG, disable = (nTab != 1)
//	titlebox tbH, disable = (nTab != 1)
//	titlebox tbI, disable = (nTab != 1)
//	titlebox tbJ, disable = (nTab != 1)
//	titlebox tbAll, disable = (nTab != 1)
	
//	Checkbox cbSingleSpec, disable = (nTab != 1)
	Checkbox cbAppendRes, disable = (nTab != 1)
	Checkbox cbDisplayRes, disable = (nTab != 1)
	Button bnToC, disable = (nTab!= 1)
	Button bnToCPS, disable = (nTab!= 1)
			
	Button bnBackShi, disable = (nTab != 1)
	Button bnBackLine, disable = (nTab != 1)
	Button bnBackSub,  disable = (nTab != 1)
	Button bnBackDiv,  disable = (nTab != 1)
	Button bnEToBE, disable = (nTab != 1)
	Button bnMakeFETable, disable = (nTab != 1)
	Button bnWArithmNormAreas, disable = (nTab != 1)
	Button bnWArithmAverWaves, disable = (nTab != 1)
	Button bnSumWaves, disable = (nTab != 1)
	Button bnWArithmBinHor,disable = (nTab != 1)
	Button bnWArithmBinVer,disable = (nTab != 1)
	PopupMenu pmWArithmBinSize, disable = (nTab != 1)
	PopupMenu pmWArithmeticsBinMode, disable = (nTab != 1)

	PopUpMenu pmBackWave,  disable = (nTab != 1)
	Button WavesToMatrix, disable = (nTab != 1)
	PopupMenu RemoveWaves, disable = (nTab != 1)
	Button SWaveArithm_APlusB, disable = (nTab != 1)
	Button SWaveArithm_AMinusB, disable = (nTab != 1)
	Button SWaveArithm_AMultB, disable = (nTab != 1)
	Button SWaveArithm_ADivB, disable = (nTab != 1)
	Button ShowWaveFromImageCursA, disable = (nTab != 1)
	Button ShowWaveFromImageCursAB, disable = (nTab != 1)
	Button ShowWaveFromImageCursAll, disable = (nTab != 1)
	
	Button SWaveArithm_APlusC, disable = (nTab != 1)
	Button SWaveArithm_AMinusC, disable = (nTab != 1)
	Button SWaveArithm_AMultC, disable = (nTab != 1)
	Button SWaveArithm_ADivC, disable = (nTab != 1)
	SetVariable SWaveArithm_C,  disable = (nTab != 1)
	Button	bnGetCValueFromCurs, disable = (nTab != 1)
	Button SWaveArithm_AToLeft, disable = (nTab != 1)
	SetVariable SWaveArithm_XShift, disable = (nTab != 1)
	Button SWaveArithm_AToRight, disable = (nTab != 1)
	button SWaveArithm_AToBShift, disable = (nTab != 1)
	popupmenu bnSetTraceColors, disable = (nTab != 1)
	popupmenu pmGetAreaInfo, disable = (nTab!=1)
	
	Button bUndo, disable = (nTab != 1)
end



//_________________________________________________


// function lbListBoxControl
// to implement double click load
function XPSFit_lbListBoxControl(ctrlName,row,col,event) : ListboxControl
	String ctrlName     // name of this control
	Variable row        // row if click in interior, -1 if click in title
	Variable col        // column number
	Variable event      // event code
	
	if (event == 3) 			// on double click do the same as on button "Load"
		XPSFit_LoadFileFunk()
	endif
	
	return 0            // other return values reserved
End
//_______________________________________________________________
proc XPSFit_LoadFile (ctrlName) : ButtonControl
	String ctrlName
	XPSFit_LoadFilefunk ()
end

proc XPS_SetRainbowColoursProc(ctrlName) : ButtonControl
	String ctrlName

	XPS_SetRainbowColours()
end

proc GetGFitInfoProc (ctrlName)
	string ctrlName
	GetGFitInfo()
end

proc DoMultiFitProc(ctrlName)
	string ctrlName
	DoMultiFit()
end

proc XPS_ChangeDir (ctrlName)
	String ctrlName
	XPS_ChangeDirFunk(1)
end

function procSubBack(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	
	if (B_Struct.eventcode == 1)
		if (getbit(3,B_Struct.eventmod))
			XPSFit_SubBackFunk(B_Struct.ctrlName, 1) // cmd is clicked
		else
			XPSFit_SubBackFunk(B_Struct.ctrlName, 0) // cmd is not clicked
		endif
	endif
end

proc ReloadFolderContent(ctrlName)
	String ctrlName
	XPS_ChangeDirFunk(0)
end

function procEToBE(ctrlName)

	String ctrlName

	XPSFit_EToBEfunc()
end


function WaveArithm(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	
	if (B_Struct.eventcode == 1)
		if (getbit(3,B_Struct.eventmod))
			XPSFit_WaveArithmFunk(B_Struct.ctrlName, 1) // cmd is clicked
		else
			XPSFit_WaveArithmFunk(B_Struct.ctrlName, 0) // cmd is not clicked
		endif
	endif
end


proc XPS_UndoOperation(ctrlname) : Buttoncontrol
	string ctrlname
	
	XPS_UndoOperationf()
end

proc ShowWaveFromImage(ctrlname):Buttoncontrol
	string ctrlname
	
	XPSFit_ShowWaveFromImageFunk(ctrlname)
end

proc procMakeFETable(ctrlname):ButtonControl
	string ctrlname
	
	XPSFit_MakeFETable()
end

proc WaveArithmGetCFromCurs(ctrlname):ButtonControl
	string ctrlname
	
	XPSFit_GetCFromCurs()
end
	
function XPSFit_GetCFromCurs()

	wave /Z w = $CsrWave(A)

	if(waveExists($CsrWave(A)))
		variable n = vcsr(A)
		string s = XWaveName("",NameOfWave(w))
		
		if(strlen(s))
			wave wX = $s
			variable nE = wX[pcsr(A)] 
		else
			nE = xcsr(A)
		endif
	else
		Abort("No cursor A on top graph")
	endif
	
	SetVariable SWaveArithm_C value = _NUM:n
	SetVariable SWaveArithm_XShift value = _NUM:nE
	

end

proc XPSFit_GetAreaProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	XPSFit_GetAreaFunc(popStr)

end

//__________________________________________________________________
function XPSFit_GetAreaFunc(sType)
	string sType
	
	string sCurFolder = GoToDataFolder()
	string sListOfWaves = TraceNameList("",";",1)
	
	variable nType
	strswitch (sType)
		case "Total":
			nType = GETAREA_TOTAL
			break
		
		case "No Shirley back":
			nType = GETAREA_NOSHIRLEY
			break
			
		case "No linear back":
			nType = GETAREA_NOLINEAR
			break
			
		case "No back, between csrs":
			nType = GETAREA_BTWCSRS
	endswitch
	
	variable nAE, nBE
	nAE = strlen(csrinfo(A)) ? xcsr(A) : inf
	nBE = strlen(csrinfo(B)) ? xcsr(B) : -inf 
	
	
	if(strlen(sListOfWaves))
		XPSFit_GetArea(sListOfWaves, nType, nAE, nBE)		
	endif
	
	SetDataFolder sCurFolder
end

function /S XPSFit_GetArea(sListOfWaves, nType, nAE, nBE)
	string sListOfWaves
	variable nType, nAE, nBE
	
	variable idx
	
	variable nNumWaves = ItemsInList(sListOfWaves)
	make /O /T /N=(nNumWaves) wAreaWaveNames
	
	for (idx = 0; idx < nnumWaves; idx += 1)
		wAreaWaveNames[idx] = StringFromList(idx, sListOfWaves)
	endfor
	
	switch (nType)
		case GETAREA_TOTAL:
			nAE = leftx(w)
			nBE = rightx(w)
		case GETAREA_BTWCSRS:
			make /O/N=(nNumWaves) wAreaTotArea
			wave wArea = wAreaTotArea
	
			for (idx = 0; idx < nnumWaves; idx += 1)
				wave w = $StringFromList(idx, sListOfWaves)
				wAreaTotArea[idx] = abs(Area(w,nAE,nBE))
			endfor
			break

		case GETAREA_NOSHIRLEY:
			make /O/N=(nNumWaves) wAreaNoShiBack
			wave wArea = wAreaNoShiBack
	
			for (idx = 0; idx < nnumWaves; idx += 1)
				string s = StringFromList(idx, sListOfWaves)
				XPSFit_SubBack( s, SHIRLEY, "", inf, inf, inf, inf, inf, inf, inf, inf, inf, inf )
				wave w = $(s+ "_wobgr")
				wAreaNoShiBack[idx] = abs(area(w,nAE, nBE))
				Killwaves /Z w
			endfor
			break
		
		case GETAREA_NOLINEAR:
			make /O/N=(nNumWaves) wAreaNoLinBack
			wave wArea = wAreaNoLinBack
	
			for (idx = 0; idx < nnumWaves; idx += 1)
				 s = StringFromList(idx, sListOfWaves)
				XPSFit_SubBack( s, LINEAR, "", inf, inf, inf, inf, inf, inf, inf, inf, inf, inf )
				wave w = $(s+ "_wobgr")
				wAreaNoLinBack[idx] = abs(area(w,nAE, nBE))
				Killwaves /Z w
			endfor
			break
	endswitch
	
	edit
	AppendToTable  wAreaWaveNames, wArea
	
	
	
	
	
	
end

//____________________________________________________________________
function /S XPSFit_GetSepStr(str,sep,nOnSide, nFirstOrLast) 
	String 	str // split this string
	string 	sep // list of separators in the order of importance. str will be separated by firts found separator
	variable 	nOnSide // returning side: -1 - left 1 - right
	variable 	nFirstOrLast // 0 - first 1 - last
	
	if (!strlen(str))
		return ""
	endif
	
	if (!strlen(sep))
		return str
	endif
	
	variable 	nStart, nEnd
	variable 	nPos = 0, nSepPos = 0
	variable 	idx
	
	
	switch (nFirstOrLast)
		case 0: // first
			nSepPos = strlen(str) -1
			for (idx = 0; idx < itemsinlist(sep); idx += 1)
				nPos = 	strsearch (str, stringfromlist(idx,sep),0)
				nSepPos = nSepPos > nPos ? nPos : nSepPos	
			endfor
			break
			
		case 1:
		default:
			nSepPos = 0
			for (idx = 0; idx < itemsinlist (sep); idx += 1)
				nPos = strsearch (str, stringfromlist(idx,sep), strlen(str) - 1, 1)
				nSepPos = nSepPos < nPos ? nPos : nSepPos
			endfor
			break
	endswitch
	
	
	switch (nOnSide)
		case 1:
			nEnd = strlen(str) - 1
			nStart = nSepPos + 1		
			break
			
		case -1:
		default:
			nStart = 0
			nEnd = nSepPos - 1
			break
	endswitch
	return str[nStart, nEnd]

end

//____________________________________________________________

function XPSFit_LoadFileFunk () // loads one or several files 
	
	Wave wListOfSelFiles = $"root:XPS_QuickFileViewer:wListOfSelFiles" // get list of all files 
	Wave/T wListOfAllFiles = $"root:XPS_QuickFileViewer:wListOfFiles" // get list of all selected files
	SVAR sFileFolderPath = root:XPS_QuickFileViewer:g_sDataFolderPath // get current folder
	
	Variable idx  = 0
	Variable nNumOfFiles = NumPnts(wListOfAllFiles) // get number of files in the folder
	String sListFilesToLoad = ""
	string sFileName
	string sCurFileName
	
	do  
		if (wListOfSelFiles[idx] == 1 || wListOfSelFiles[idx] == 8) // if file selected (first in multiple selection)
 			 sListFilesToLoad+= wListOfAllFiles[idx] + ";" // write its path in a string
		endif
		
		idx += 1
		
		if (idx == nNumOfFiles) // when reach bottom of file list
			break
		endif
		
	while (1) // use break
	
	
	
	if (strlen(sListFilesToLoad) == 0) // if no selection
		Abort ("No file selected")
	endif
	variable nType
	string sWaveList = ""
	ControlInfo LoadMenu // get name of load method
	
	for (idx = 0; idx < itemsinlist(sListFilesToLoad); idx += 1) // do it for each file in the list
		
		sCurFileName = stringFromList(idx, sListFilesToLoad)
		
		//**************** get file type________________
		
		strswitch (s_value)
			
			case "XPS Auto":
				strswitch (XPSFit_GetSepStr(sCurFileName, ".",1,1)) // check for extention
					
					case "xy":
						nType = SPECSXY
						break
					
					case "xml":
						nType = SPECSXML
						break
					
					case "ibw":
						nType = IGORBINARY
						break
					
					case "itx":
						nType = IGORTEXT
						break
						
					case "Fiits":
						nType = NEXAFSFITS
						break
						
					case "txt":
					case "dat":
						nType = GENERALTEXT
						break
					
					case "pxp":
					case "pxt":
						nType = IGOREXP
						break
					
					default:
						LoadWave /J/O/K=2/B="N=TempWaveL;" /A (sFileFolderPath +sCurFileName)
					 	wave/T wTempWaveL = $"TempWaveL"
					 	if (cmpstr(wTempWaveL[0], "IGOR") == 0) // igor text
						 	nType = IGORTEXT
					 	else // general text
					 		nType = GENERALTEXT
					 	endif
						break
						
				endswitch
				break
				
			case "General Text":
				nType = GENERALTEXT
				break
			
			case "Igor Text":
				nType =IGORTEXT
				break
				
			case "Igor Binary":
				nType =  IGORBINARY
				break

			case "Specs XML, XY":
				strswitch (sFileName[strlen(sFileName) - 3, strlen(sFileName) - 1])
					case ".xy":
						nType = SPECSXY
						break
					
					case "xml":
						nType = SPECSXML
						break
						
				endswitch
				break
			
			case "FITS NEXAFS":
				nType = NEXAFSFITS
				break
			
			case "NEXAFS 1D":
				nType =NEXAFS1D
				break
			
			case "pxp":
			case "pxt":
				nType = IGOREXP
				break 
		
		endswitch
		
		//***************** load data from single file*************	
		
		switch (nType)
			
			case GENERALTEXT:			
				 sWaveList += XPSFit_LoadGeneralText(sCurFileName, sFileFolderPath)
				break
			
			case IGORTEXT:
				sWaveList += XPSFit_LoadIgorText(sCurFileName, sFileFolderPath,0)
				break
				
			case IGORBINARY:
				sWaveList += XPSFit_LoadIgorText(sCurFileName, sFileFolderPath,1)
				break

			case SPECSXY:
				sWaveList += XPSFit_LoadSpecsText(sCurFileName, sFileFolderPath) 
				break
				
			case SPECSXML:
				sWaveList += XPSFit_LoadSpecsXMLText(sCurFileName, sFileFolderPath) 
				break
			
			case IGOREXP:
				sWaveList += XPSFit_LoadIgorExp(sCurFileName, sFileFolderPath) 
				break
			
			case NEXAFS1D:
				 XPSFit_LoadNEXAFS1D(sCurFileName,sFileFolderPath)
				break
				
			case NEXAFSFITS:
				XPS_loadFITS(sCurFileName,sFileFolderPath)
				break		
			
		endswitch
	
	endfor

	ControlInfo cbDisplay
	
	if (v_value)
		Display
		string sGraphWin = WinName(0,1)
		
		for (idx = 0; idx < itemsInList(sWaveList); idx += 1)
			wave /Z w = $StringFromList(idx,sWaveList)
			if (!WaveExists(w))
				continue
			endif
	
			if (dimSize(w,1) > 0)
				Display
				AppendImage w
			else
				AppendToGraph /W = $sGraphWin w
			endif
		
		endfor
	
		if (!strlen(TraceNameList(sGraphWin, ";", 1)))	
			KillWindow $sGraphWin
		endif
	endif
	
	
	
	
end
//_____________________________________________________________

// Change file directory 

function XPS_ChangeDirFunk(bReload)
	Variable bReload
	
	SVAR sDataFolderPath = root:XPS_QuickFileVIewer:g_sDataFolderPath
	
	If (bReload)
		getfilefolderinfo /D/Q 
		sDataFolderPath = s_path
		newpath /O sPath sDataFolderPath
	endif
	
	String sListOfFiles = IndexedFile(sPath, -1,"????")
	Variable nNumOfFiles = ItemsInList(sListOfFiles)
	Make /O/T/N=(nNumOfFiles) root:XPS_QuickFileVIewer:wListOfFiles
	Wave/T wListOfFiles = $("root:XPS_QuickFileVIewer:wListOfFiles")
	Make /O/N=(nNumOfFiles) root:XPS_QuickFileVIewer:wListOfSelFiles
	Wave wListOfSelFiles = $("root:XPS_QuickFileVIewer:wListOfSelFiles")	
	wListOfSelFiles = 0
	Variable i
	
	for (i = 0; i < nNumOfFiles; i += 1)
		wListOfFiles[i]= StringFromList(i,sListOfFiles)
	endfor	
	
	sort /A wListOfFiles, wListOfFiles
end
//________________________________________________________________

// Remove traces from graph according to a rule

Function RemoveWaves(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	if (cmpstr(popStr,"all except visible") == 0)
		RemoveTracesFromWnd(0)
	endif
	
	if (cmpstr(popStr,"partially visible") == 0)
		RemoveTracesFromWnd(-1)
	endif
	
	if (cmpstr(popStr,"fully visible") == 0)
		RemoveTracesFromWnd(1)
	endif

end
//_______________________________________________________________

Function XPSFit_MakeView(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	string sList = WaveList("*", ";", "WIN:")
	//print popStr, stringmatch (popstr, "Fully organized")
	
	variable idx 
	
	if(stringmatch (popstr, "Fully organized") == 1)
		for (idx = 0; idx < itemsinlist(sList); idx += 1)
			string sWName = stringfromlist(idx, sList)
			variable nPos = strsearch(sWName, "_", strlen(sWName) -1, 1)
			string sEnd = sWName[nPos+1, strlen(sWName) - 1]
			//print "->",sWName, sEnd
			//print stringmatch(sWName[0,2], "fit"),  hasstr(sEnd)
			if (stringmatch(sWName[0,2], "fit") != 1 && hasstr(sEnd))
				print "this:", sWName,sEnd
			else
				//print "not this:",sWName
			endif
			
			
		endfor
	endif
	
	
	
end

function hasstr(str)
	string str
	
	variable idx
	for (idx = 0; idx < strlen(str); idx += 1)
		//print str[idx]
		if (char2num(str[idx]) <=  48 ||  char2num(str[idx]) >= 57)
			//print str[idx]
			return 1
		endif
	endfor
	return 0
end


//__________________________________________________

//
function /S XPSFit_LoadIgorExp(sFileName, sFolderPath)
	String sFileName, sFolderPath // single file
	
	NVAR bOverWriteWave = root:XPS_QuickFileViewer:g_bOverWriteWave
	NVAR bUseFileName = root:XPS_QuickFileViewer:g_bUseFileName
	
	string sCurFolder = GetDataFolder(1)
	NewDataFolder XPSFit_TempDataFolder
	SetDataFolder XPSFit_TempDataFolder
	
	LoadData /Q/L=1 (sFolderPath +sFileName)
	variable nNumWaves = CountObjects("",1)
	
	if(bUseFileName)
		string sNewFileNameBase = sFileName[0,strlen(sFileName) - 5]
	else
		sNewFileNameBase = ""
	endif
	
	 sNewFileNameBase = XPSFit_CheckWaveName(sNewFileNameBase)
	 
	string sWaveName
	string sNewFileName
	string sWaveList = ""
	
	variable idx
	
	for (idx = 0; idx < nNumWaves; idx += 1)
		sWaveName = GetIndexedObjName("",1,idx)
		//print sWaveName
		sNewFileName = sNewFileNameBase 
		
		if (nNumWaves > 1)
			sNewFileName +=  "_" + num2str(idx)
		endif
		
		if (dimsize($sWaveName,1))
			sNewFileName += "_M"
		endif
				
		if(!WaveExists($(sCurFolder + sNewFileName)) || (WaveExists($(sCurFolder + sNewFileName)) && bOverWriteWave) )
			Duplicate /O $sWaveName $(sCurFolder + sNewFileName)
			sWaveList += sNewFileName + ";"
		endif

		
	endfor


	SetDataFolder sCurFolder
	KillDataFOlder XPSFit_TempDataFolder

	return sWaveList
end

//_______________________________________________
// loads General Text wave

function /S XPSFit_LoadGeneralText (sFileName, sFolderPath)  // load from single file
	String sFileName, sFolderPath // single file
	
	NVAR bOverWriteWave = root:XPS_QuickFileViewer:g_bOverWriteWave
	NVAR bUseFileName = root:XPS_QuickFileViewer:g_bUseFileName
	
	LoadWave /O/G /M /N=TempWave /Q (sFolderPath +sFileName) // load it as matrix
	string sWaves = WaveList("TempWave*", ";", "") 
	
	if (strlen(sWaves) == 0)
		return ""
	endif
	
	string sWaveList = ""
	string sNewName

	if(bUseFileName)
		string sNewNameBase =  sFileName
	else
		sNewNameBase = ""
	endif
	
	sNewNameBase = XPSFit_CheckWaveName(sNewNameBase)
	
	variable idx = 0
	variable nLeftE,nRightE
	for (idx = 0; idx < ItemsInList(sWaves); idx += 1)
		
		string sName = StringFromList(idx, sWaves)
		wave w = $sName
		nLeftE = w[0][0]
		nRightE = w[DimSize(w,0) - 1][0]
		Deletepoints /M = 1 0,1,w
		SetScale /I x, nLeftE, nRightE, w // change scale
		
		sNewName = sNewNameBase
		if (DimSize(w,1) > 2) // rename
			
			if (ItemsInList(sWaves) > 1)
				sNewName += "_" + num2str(idx)
			endif
			
			sNewName += "_M"
			
		else 
			Redimension /N = (DimSize(w,0),0) w

			if (ItemsInList(sWaves) > 1)
				sNewName += "_" + num2str(idx)
			endif	
					
		endif
		
		sWaveList += sNewName + ";"
		if (bOverWriteWave || !WaveExists($sNewName))
			duplicate /O $sName, $sNewName		
		endif	
		
	endfor
	
	for (idx = 0; idx< ItemsInList(sWaves); idx += 1)
		KillWaves $(stringfromlist(idx,sWaves)) // remove all temporary waves
	endfor

 return sWaveList
end

//__________________________________________________________________________

function XPS_loadFITS(sFileToLoad,sFileFolderPath)
	string sFileToLoad,sFileFolderPath
	
	wave /T wFITS = root:XPS_QuickFileViewer:wFITSLoadList
	wave /T wFITSN = root:XPS_QuickFileViewer:wFITSNameList
	
	SVAR sFITSPE = root:XPS_QuickFileViewer:g_FITSPE
	
	string sDF = GetDataFolder(1)
		
		string spath = sFileFolderPath// + stringFromList(0,sFileToLoad)
		variable refnum
		newpath/O path,  spath
		string sPE, sInt, sI0
		string sWPath
		string sList = ""

		variable idx = 0, i =0, j = 0
		string s
		variable nFilesInList = ItemsInList(sFileToLoad)
		for (idx = 0; idx < nFilesInList; idx+= 1)
			Open/R/P=path/T="????" refnum as stringFromList(idx,sFileToLoad)
			string sDFName = XPSFit_CheckWaveName(stringfromlist(itemsinlist(s_fileName,":") - 1, s_fileName, ":"))
			sDFName =  sDFName[0,strlen(sDFName)-6]
			LoadOneFITS(refnum, sDFName,0,0,0,0,0,0)
			close refnum
			
			setdatafolder  sDF + sDFName + ":Extension1"
			
			sPE = sDFName + "_hv"	
			
			for (i = 0; i < dimsize(wFITS,0); i += 1)
				if (strlen(wFITS[i]))
					//sI0 = sDFName + "_" + wFITSN[i]
					string sWList = WaveList(wFITS[i] + "*", ";", "") 
					
					for (j = 0; j < itemsinlist(sWList); j += 1)
						
						if (j)
							s = num2str(j)
						else
							s = ""
						endif	
						Duplicate /O $(stringfromlist(j,sWList)) $(sDF + sDFName + "_" + wFITSN[i]+ s )
						sList += sDF + sDFName + "_" + wFITSN[i]+ s  + ";"
					endfor
		
				endif
			endfor
			
			wave /Z w = $sFITSPE
			//print "name :", NameOfWave(w)
			if (!WaveExists(w))
				SetDataFolder sDF
				//KillDataFolder $sDFName
				abort "Name of photon energy wave does not match FITS data."
			endif
			
			Duplicate /O $(NameOfWave(w)) $(sDF + sPE)
			SetDataFolder sDF
			KillDataFolder $sDFName
			//if (nFilesInList == 1) // if only single file to load
				Display
				for (i = 0; i < itemsinlist(sList); i += 1)
					AppendToGraph $(stringfromlist(i,sList)) vs $ sPE
				endfor
				//AppendToGraph $sI0 vs $ sPE
				//EToBE(NewWaveName, "", 1) // ask about fermi energy etc
			//endif
		endfor
end


//_________________________________________________________________________


function XPSFit_LoadNEXAFS1D (sFileList, sFolderPath)  
	String sFileList, sFolderPath

	NVAR g_nColumnhv = root:XPS_QuickFileViewer:g_ColumnE
	NVAR g_nColumnI = root:XPS_QuickFileViewer:g_ColumnInt
	SVAR g_sXASPrefix = root:XPS_QuickFileViewer:g_XASPrefix
	
	variable nColumnhv = g_nColumnhv
	variable nColumnI = g_nColumnI
	string sXASPrefix = g_sXASPrefix
	
	Variable nFilesInList = ItemsInList(sFileList)
	if (nFilesInList == 0)
		Abort ("Something went wrong. Goodbye.")
	endif
	
	if ((nColumnhv == 0) || (nColumnI==0))
		prompt nColumnhv, "Photon energy column number" 	//enter BE columnt number
		prompt nColumnI, "Data column number"	//enter Data column number
		prompt sXASPrefix, "Name prefix (for file names starting with a number)"
		DoPrompt "Load General Text", nColumnhv, nColumnI,sXASPrefix
		if (v_flag == 1)
			return 0
		endif
	endif
	
	g_nColumnhv = nColumnhv
	g_nColumnI = nColumnI
	g_sXASPrefix = sXASPrefix
	
	String shvWaveName="TempWave"+num2str(nColumnhv-1)	//set the name of the temp wave with BE scale to TempWave_BE columnt number
	String sIntWaveName="TempWave"+num2str(nColumnI-1)		// set the name of the temp wve with data to TempWave_Data_columnt_number
	VAriable idx = 0
	String NewIntWaveName = ""
	String NewhvWaveName = ""
	string s = ""
	
	for (idx = 0; idx < nFilesInList; idx += 1)
		Execute "LoadWave /G /N=TempWave \"" + sFolderPath + stringfromlist(idx,sFileList) + "\""
		s = XPSFit_CheckWaveName(stringfromlist(idx,sFileList)[0,strlen(stringfromlist(idx,sFileList))-5])
		
		if(strlen(s))
			NewIntWaveName = XPSFit_CheckWaveName(s) + "_I"
			NewhvWaveName = XPSFit_CheckWaveName(s) + "_hv"
			Duplicate /O $sIntWaveName $NewIntWaveName
			Duplicate /O $shvWaveName $NewhvWaveName
		
			if (nFilesInList == 1) // if only single file to load
				Display
				AppendToGraph $NewIntWaveName vs $ NewhvWaveName
			endif
			
			Variable i = 0
			String sListOfTempWaves =WaveList("TempWave*",";","") 

			for (i = 0; i< ItemsInList(sListOfTempWaves); i += 1)
				KillWaves /Z $(stringfromlist(i,sListOfTempWaves)) // remove all temporary waves
			endfor
		endif
		
		
	endfor
	
end
//______________________________________________________________________________

// Adds prefix for wave names starting with a number

function/S XPSFit_CheckWaveName(sName) 
	String sName
	
	SVAR g_NamePrefix = root:XPS_QuickFileViewer:g_NamePrefix

	if (strlen (g_NamePrefix) == 0)
		g_NamePrefix = "X_"
	endif
	
	variable t = 1
	string str = ""
	
	if(strlen(sName) == 0 || strlen(sName) > 31)
		
		do
			if(t > 9)
				str = "X_0" + num2str(t) 
				
			else
				str = "X_00" + num2str(t) 
			endif
			
			string sWaveList = WaveList(str + "*", ";", "")
			
			if(strlen(sWaveList))
				t += 1
			else
				break
			endif
		
		while (1)
		
		DoAlert /T="Cannot rename" 1, "Cannot assign a name. Name as " + str + " ?"
		
		if(v_flag == 1)
			return str
		elseif(v_flag == 2)
			return ""
		endif
		
	endif
	
	string s
	variable nPos = strlen(sName) - 1
	variable idx = 0
	
	for (idx = strlen(sName) - 1; idx >= strlen(sName) - 4; idx -= 1)
		s = sName[idx]
		if (stringmatch(s, "."))
			nPos = idx - 1
		endif
	endfor
	
	sName = sName[0,nPos]
	
	//if (strlen(sName) > 31)
	//	KillWaves /Z sName
	//	Abort "A name of " + sName + " wave is too long."
	//endif
	
	if (48<=char2num(sName[0]) && 57>=char2num(sName[0]))
		sName = g_NamePrefix + sName 
	endif
	
	for (idx = 0; idx < strlen(sName); idx += 1) // replace symbols with "_"
		s = sName[idx]
		//print idx, s, NewWaveName
		if((char2num(s)>=48 && char2num(s) <= 57) || (char2num(s)>=65 && char2num(s) <= 90) || (char2num(s)>=97 && char2num(s) <= 122) || char2num(s) ==  95  )
		
		else
			sName = sName[0,idx-1] + "_" + sName[idx + 1, strlen(sName)-1]
		endif
	endfor
	
	return sName
end
//________________________________________________________________________________

//Loads waves in igor format

function /S XPSFit_LoadIgorText(sFileToLoad, sFileFolderPath,bIsBinary)
	string sFileToLoad, sFileFolderPath
	variable bIsBinary
	
	SVAR g_NamePrefix = root:XPS_QuickFileViewer:g_NamePrefix
	String sName, sList = ""
	variable idx
		
	if (bIsBinary)
		LoadWave /O /Q (sFileFolderPath + sFileToLoad)
	else
		LoadWave  /O /T /Q (sFileFolderPath + sFileToLoad)
	endif

	for (idx = 0; idx < itemsinlist(S_waveNames); idx += 1)	
		sName =  XPSFit_CheckWaveName(stringfromlist(idx,S_waveNames)) 
		if (!stringmatch(sName,stringfromlist(idx,S_waveNames)))
			duplicate /O $stringfromlist(idx,S_waveNames) $sName
			KillWaves $stringfromlist(idx,S_waveNames)
		endif
		sList += sName	+ ";"
	endfor

	return sList
end

//___________________________________________________________________________
// converts Energy types (kinetic to binding) and calibrates by fermi energy

function XPSFit_EToBEfunc ()
	
	NVAR /Z nFermi = root:XPS_QuickFileViewer:g_nFermi
	SVAR /Z sEnergyType = root:XPS_QuickFileViewer:g_sEnergyType
	
	variable nFermi_ = nFermi
	String sEnergyType_= sEnergyType
	string sFermiWave
	string sFermiWaveList = "None;" + WaveList("Fermi*", ";", "")
	
	Prompt sEnergyType_, "Energy Type", popup, "Kinetic energy;Binding energy"
	Prompt sFermiWave, "List of Fermi Energies", popup, sFermiWaveList
	prompt nFermi_, "Enter Ef, please"
	DoPrompt "Calibrate", sEnergyType_,sFermiWave,nFermi_
	
	if (v_flag == 1)
		return 0
	endif
	
	nFermi = nFermi_
	sEnergyType = sEnergyType_
	
	string sCurFolder = ""
	sCurFolder = GotoDataFolder()
	string sWaveList
	
	if(strlen(ImageNameList("",";")))
		sWaveList = ImageNameList("",";")
	else
		sWaveList = TraceNameList("",";",1)
	endif
	
	sWaveList = SortList(sWaveList,";",16)
	
	variable nleftE,nrightE
	variable idx
	
	variable nMode = MODE_BE
	
	if(stringmatch(sEnergyType, "Kinetic energy"))
		nMode = MODE_KE
	endif
	
	
	if(stringmatch(sFermiWave, "none"))
		// save to history
		XPSFit_SaveToHistory(1,sWaveList,WinName(0,1),ARITHM_ETOBE, num2str(nFermi),num2str(nMode))
	else
		XPSFit_SaveToHistory(1,sWaveList,WinName(0,1),ARITHM_ETOBE, sFermiWave,num2str(nMode))
	endif

	// do conversion
	XPSFit_EToBE(sWaveList, nFermi,nMode,sFermiWave)

	
	if (strlen(sCurFolder))
		SetDataFOlder sCurfolder
	endif
end	

//_____________________________________________________________
function XPSFit_GetFermiFromFETable(sFETable, sWaveName)
	string sFETable, sWaveName
	
	wave /T wFETable = $sFETable
	
	if(!strlen(sFETable) || !strlen(sWaveName) || DimSize(wFETable,1) < 2)
		abort
	endif
	
	variable idx
	
	for (idx = 0 ; idx < DimSize(wFETable ,0); idx += 1)
		if(stringmatch(wFETable[idx][0], sWaveName))
			return str2num(wFETable[idx][1])
		endif
	endfor
	
	return inf

end


//_______________________________________________________________

function XPSFit_EToBE(sWaveList, nParam, nMode, sFermiWave)
	string sWavelist
	variable nParam
	variable nMode
	string sFermiWave
	
	wave	w2DWave = $StringFromList(0,sWaveList)
	wave/T /Z wFermiWave = $sFermiWave
	
	variable	nDimSize = DimSize(w2DWave,1)
	variable nFermi = nParam	
	variable nTempFermi = inf
	variable nLeftE, nRightE, idx
	
	if(nDimsize)	
		if(stringmatch(sFermiWave,"none"))			
			nLeftE = DimOffset(w2DWave,0)
			nRightE = nLeftE + (DimSize(w2DWave,0) - 1) * DimDelta(w2DWave,0)

			if(nMode == MODE_KE)
				nleftE = nFermi - nLeftE
				nRightE = nFermi - nRightE 
			else
				nLeftE = nLeftE - nFermi
				nRightE = nRightE - nFermi
			endif
		
			SetScale /I x nLeftE, nRightE, w2DWave
		else
			string sTempWaveList = XPSFit_ShowWaveFromImage(w2DWave, 0, nDimSize, 2)
			//print sTempWaveList
			for(idx = 0; idx < nDimSize; idx += 1)
				//print StringFromList(idx, sTempWaveList)
				wave w = $StringFromList(idx, sTempWaveList)
				nleftE = Leftx(w)
				nrightE = Rightx(w) - deltax(w)
				nFermi = XPSFit_GetFermiFromFETable(sFermiWave,StringFromList(idx, sTempWaveList))
				nFermi = nFermi == inf ? nTempFermi : nFermi
				
				if((char2num(num2str(nFermi))< 48 || char2num(num2str(nFermi))> 57) && char2num(num2str(nFermi)) != 45)
					continue
				endif
				
				nTempFermi = nFermi
				if(nMode == MODE_KE)
					nleftE = nFermi - nLeftE
					nRightE = nFermi - nRightE 
				else
					nLeftE = nLeftE - nFermi
					nRightE = nRightE - nFermi
				endif
				
				SetScale /I x nLeftE, nRightE, w
			endfor
			
			wave wNewWave = $(XPSFit_MakeMatrix (sTempWaveList, ""))
			Duplicate /O wNewWave w2DWave
			string s = (NameOfWave(wNewWave) + ";" + sTempWaveList)
			for(idx = 0; idx< itemsinlist(s); idx += 1)
				killwaves /Z $stringfromlist(idx,s)
			endfor
		
		endif
	else
		for(idx = 0; idx < ItemsInList(sWaveList); idx += 1)
			wave w = $stringfromlist(idx,sWaveList)
			nleftE = Leftx(w)
			nrightE = Rightx(w) - deltax(w)
			
			if(WaveExists(wFermiWave))
				nFermi = XPSFit_GetFermiFromFETable(sFermiWave,StringFromList(idx, sWaveList))
				nFermi = nFermi == inf ? nTempFermi : nFermi
				
			if((char2num(num2str(nFermi))< 48 || char2num(num2str(nFermi))> 57) && char2num(num2str(nFermi)) != 45)
					continue
				endif
				
				nTempFermi = nFermi
			endif
			
			if(nMode == MODE_KE)
				nleftE = nFermi - nLeftE
				nRightE = nFermi - nRightE 
			else
				nLeftE = nLeftE - nFermi
				nRightE = nRightE - nFermi
			endif
				
			SetScale /I x nLeftE, nRightE, w
		endfor
	endif
	
end
	
	

//_____________________________________________________________
//function XPSFit_NormBackFunk()
		
//	string sCurFolder = GoToDataFolder()
//	string sWaveList = WaveList("*", ";", "WIN:")
//	string sCsr = CsrWave(A)
//	variable nE = inf
	
//	if (strlen(sCsr))
//		nE = xcsr(A)		
//	endif
	
//	XPSFit_NormBack(sWaveList, nE)
	
//	SetDataFOlder sCurFolder
//end


//function XPSFit_NormBack(sWaveList, nE)
///	string sWaveList
//	variable nE
	
//	nvar nAverXWidth = root:XPS_QuickFileViewer:g_nAverageXWidth

//	variable nY
//	variable idx
	
//	for (idx = 0; idx < itemsinlist(sWaveList); idx += 1)
//		wave w = $stringfromlist(idx,sWaveList)

//		if (nE == inf)
//			nE = min(leftx(w),rightx(w)) + nAverXWidth / 2
//		endif	
//		WaveStats /Q/ R=(nE -  nAverXWidth / 2,  nE + nAverXWidth / 2) w
//		w = w / v_avg
//	endfor
	
//end

//_______________________________________________________________
//function DivWave (a,b)
///wave a
//Variable b
//return a/b
//end


//_____________________________________________________________

// subtracts backgrounds
function XPSFit_SubBackFunk(ctrlName,bSingle)	
	string ctrlName
	variable bSingle
		
	NVAR /Z bDisplayWArithmRes =  root:XPS_QuickFileViewer:g_bDisplayWArithmRes
	NVAR /Z bAppendWArithmRes =  root:XPS_QuickFileViewer:g_bAppendWArithmRes
	nvar nAverXWidth = root:XPS_QuickFileViewer:g_nAverageXWidth
	
	string sCurDataFolder = GotoDataFolder()
	variable nBackType
	string sParam
	variable idx
	
	strswitch (ctrlName)
		case "bnBackShi":
			nBackType = SHIRLEY
			break

		case "bnBackLine":
			nBackType = LINEAR
			break	
		
		case "bnBackSub":
			nBackType = SUBBACK
			break
			
		case "bnBackDiv":
			nBackType = DIVBACK
			break
			
		default:
			nBackType = NOBACK
			break		
	endswitch

	variable nAE, nBE, nCE, nDE, nEE, nFE, nGE, nHE, nIE, nJE 
	nAE = strlen(csrinfo(A)) ? xcsr(A) : inf
	nBE = strlen(csrinfo(B)) ? xcsr(B) : inf 
	nCE = strlen(csrinfo(C)) ? xcsr(C) :  inf
	nDE = strlen(csrinfo(D)) ? xcsr(D) : inf 
	nEE = strlen(csrinfo(E)) ? xcsr(E) :  inf
	nFE = strlen(csrinfo(F)) ? xcsr(F) :  inf
	nGE = strlen(csrinfo(G)) ? xcsr(G) :  inf
	nHE = strlen(csrinfo(H)) ? xcsr(H) : inf 
	nIE = strlen(csrinfo(I)) ? xcsr(I) :  inf
	nJE = strlen(csrinfo(J)) ? xcsr(J) : inf
	
	// choose wave to subtract wave
	
	controlInfo pmBackWave
	if (stringmatch("Cursor/Original data", s_value) )
		string sBackWave = ""
	else
		sBackWave = s_value	
	endif
	
	string sWaveList
	
	// choose waves where to subtract from
	
	if(strlen(ImageNameList("",";")))
		sWaveList = XPSFit_RemoveSWaves(ImageNameList("",";"),0, "_wobgr") // matrix wave
	else
		if (bSingle) // 1D waves
			sWaveList = XPSFit_RemoveSWaves(CsrWave(A),0, "_wobgr")
			
			if(!strlen(sWaveList))
				return 0
			endif
		else
			sWaveList = XPSFit_RemoveSWaves(TraceNameList("",";",1),0, "_wobgr") // multiple waves
		endif
	endif
	
	//Save to history
	
	if (nAe == inf)
		nAE  = min(leftx($StringFromList(0,sWaveList)),rightx($StringFromList(0,sWaveList))) + nAverXWidth / 2
	endif
						
	if (((nBackType == SUBBACK) || (nBackType == DIVBACK)) && !strlen(sBackWave))
		for(idx = 0; idx < itemsinlist(sWaveList); idx += 1)
			WaveStats /Q /R=(nAE -  nAverXWidth / 2,  nAE + nAverXWidth / 2) $StringFromList(idx,sWaveList)
			XPSFit_SaveToHistory(idx ? 0 : 1,StringFromList(idx,sWaveList),WinName(0,1),nBackType,num2str(v_avg), "")
		endfor
	endif
	

	// Subtract background
	string sBackWaveList = XPSFit_SubBack(sWaveList, nBackType, sBackWave,nAE, nBE, nCE, nDE, nEE, nFE, nGE, nHE, nIE, nJE )	// subtracts backgrounds from list of wave; in return gets list of waves without backs
	
	
	
	if ((nBackType == SUBBACK || nBackType == DIVBACK) && !strlen(sBackWave))
		SetDataFolder sCurDataFolder
		return 1
	endif
	
		
	if(bAppendWArithmRes && !DimSize($(WaveName("",0,1)),1))
		//sBackWaveList += sBackWaveList + "background"
		for(idx = 0; idx < itemsinlist(sBackWaveList); idx += 1)
			wave w = $StringFromList(idx, sBackWaveList)
			if (FindListItem(NameOfWave(w), TraceNameList("",";",1)) == -1)
				AppendToGraph w
			endif
		endfor	
	endif	
	
	if(bDisplayWArithmRes)
		sBackWaveList = RemoveFromList("background", sBackWaveList)
		for(idx = 0; idx < itemsinlist(sBackWaveList); idx += 1)
			wave w = $StringFromList(idx, sBackWaveList)
			if (DimSize(w,1))
				display
				AppendImage w
			else
					if(idx == 0)
						display
					endif
					AppendToGraph w
				
			endif
		endfor	
	endif
	
	SetDataFolder sCurDataFolder
end
//______________________________________________________

function /S XPSFit_RemoveSWaves(sWaveList,idx, str)
	string sWaveList
	variable idx // start index
	string str
	
	if (idx == 0)
		sWaveList = RemoveFromList("background", sWaveList)
	endif
	
	if (idx > ItemsInList(sWaveList) - 1)
		return sWaveList
	endif
	
	string st = StringFromList(idx, sWavelist)
	string sWaveListW = RemoveFromList(st + str, sWaveList)
	
	if (strlen(sWaveList) == strlen(sWaveListW))
		sWaveList = XPSFit_RemoveSWaves(sWaveListW, idx + 1, str)
	else
		sWaveList = XPSFit_RemoveSWaves(sWaveListW, idx, str)
	endif
	
	return sWaveList
	
end

//_______________________________________________________

function /S XPSFit_SubBack( sWaveList, nBackType, sBackWave, nAE, nBE, nCE, nDE, nEE, nFE, nGE, nHE, nIE, nJE ) // (if 2D wave - get single wave, subtract back, put into new 2D etc)
	string sWaveList
	variable nBackType // 0 - no back, 1 - shirley, 2 - line
	string sBackWave
	variable nAE, nBE, nCE, nDE, nEE, nFE, nGE, nHE, nIE, nJE 
	
	nvar nAverXWidth = root:XPS_QuickFileViewer:g_nAverageXWidth
	
	variable nY
	variable idx
	wave w2DWave = $stringfromlist(0,sWaveList)
	variable nDimSize = DimSize(w2DWave,1)
	string sBackWaveList = ""
	
	if (nDimSize)
		variable nNumWaves = nDimSize
	else
		nNumWaves = Itemsinlist(sWaveList)
	endif
	

	for (idx = 0 ; idx < nNumWaves; idx += 1)
		
		if (nDimSize)
			wave w = XPSFit_GetWaveFromMatrix(w2DWave,idx)
		else
			wave w = $StringFromList(idx, sWaveList)
		endif
	
		switch (nBackType)
			
			case SUBBACK:
			case DIVBACK:
				
				if(strlen(sBackWave))
					wave wB = $sBackWave
					
					if(nDimSize)
						if (idx == 0)
							duplicate /O w2DWave $(NameOfWave(w2dWave) + "_wobgr") 
							wave w2DWaveNoBrg = $(NameOfWave(w2dWave) + "_wobgr") 
							sBackWaveList += NameOfWave(w2DWaveNoBrg) + ";"
						endif	
						
						switch (nBackType)
							case SUBBACK:
								w2DWaveNoBrg[][idx] = w(x) - wB(x)
								break
					
							case DIVBACK:
								w2DWaveNoBrg[][idx] =  w(x) / wB(x)
								break		
						endswitch				
					else
						Duplicate /O w $(NameOfWave(w) + "_wobgr")
						wave wWoB = $(NameOfWave(w) + "_wobgr")
						
						switch (nBackType)
							case SUBBACK:
								wWoB = w(x) - wB(x)
								break
					
							case DIVBACK:
								wWoB = w(x) / wB(x)
								break		
						endswitch
						sBackWaveList += NameOfWave(wWoB) + ";"
					endif
				else
					if (nAe == inf)
						nAE  = min(leftx(w),rightx(w)) + nAverXWidth / 2
					endif
	
					WaveStats /Q /R=(nAE -  nAverXWidth / 2,  nAE + nAverXWidth / 2) w

					switch (nBackType)
						case SUBBACK:
							w = w - v_avg
							break
				
						case DIVBACK:
							w = w / v_avg
							break		
					endswitch
					
					if(nDimSize)
						w2DWave[][idx] = w[p]
					endif
				endif
				break
				
			
			case SHIRLEY:
			case LINEAR:
				wave wB = XPSFit_Back(w,nBackType, sBackWave, nAE, nBE, nCE, nDE, nEE, nFE, nGE, nHE, nIE, nJE)
				
				if (nDimSize)
					if (idx == 0)
						duplicate /O w2DWave $(NameOfWave(w2dWave) + "_wobgr") 
						wave w2DWaveNoBrg = $(NameOfWave(w2dWave) + "_wobgr") 
						sBackWaveList += "background;" + NameOfWave(w2DWaveNoBrg) + ";"
					endif	
					
					w2DWaveNoBrg[][idx] = w2DWave(x)[idx] - wB(x)
				else
					if (idx == 0)
						sBackWaveList += "background;"
					endif
					Duplicate /O w $(NameOfWave(w) + "_wobgr")
					wave wWoB = $(NameOfWave(w) + "_wobgr")
			
					wWoB = w(x) - wB (x)
					sBackWaveList += NameOfWave(wWoB) + ";"
				endif

				break
		endswitch
		
	endfor
	
	return sBackWaveList 
end
	

	
	
	
	
//	String CurrentWaveName, sBWave
//	Variable ShowRes,BackType, nAE, nBE, nCE, nDE, nEE, nFE, nGE, nHE, nIE, nJE 
//
//	Variable AverageRightY, AverageLeftY
//	
//	//silent 1
//	if (strlen(CurrentWaveName)==0) // if function is called by  user and not the internal function
//		if (!strlen(csrinfo(A))) // if cursor not A on the wave
//			CurrentWaveName=StringFromList(0,WaveList("*", ";","WIN:")) // then we work with the top graph
//			nAE=rightx($CurrentWaveName)+0.5
//			nBE=leftx($CurrentWaveName)-0.5
//		else // if cursor A on the graph
//			CurrentWaveName = csrwave (A) // work with wave with csr A
//			nAE = xcsr(A)
//			nBE = strlen(csrinfo(B)) ? xcsr(B) : -1 
//			nCE = strlen(csrinfo(C)) ? xcsr(C) : -1 
//			nDE = strlen(csrinfo(D)) ? xcsr(D) : -1 
//			nEE = strlen(csrinfo(E)) ? xcsr(E) : -1 
//			nFE = strlen(csrinfo(F)) ? xcsr(F) : -1 
//			nGE = strlen(csrinfo(G)) ? xcsr(G) : -1 
//			nHE = strlen(csrinfo(H)) ? xcsr(H) : -1 
//			nIE = strlen(csrinfo(I)) ? xcsr(I) : -1 
//			nJE = strlen(csrinfo(J)) ? xcsr(J) : -1 
//			
//			if (nBE == -1 && nCE == -1 && nDE == -1 && nEE == -1 && nFE == -1 && nGE == -1 && nHE == -1 && nIE == -1 && nJE == -1)
//				//print "here"
//				nAE=rightx($CurrentWaveName)+0.5
//				nBE=leftx($CurrentWaveName)-0.5	
//			endif		
//		endif
//	endif
	
//	variable nAI = -1, nBI = -1, nCI = -1, nDI = -1, nEI = -1, nFI = -1, nGI = -1, nHI = -1, nII = -1, nJI = -1
	
//	variable p, r = 0
//	make /O/N=10 tmpsortwave
//	wave tw = 'tmpsortwave'
//	tw[0] = nAE
//	tw[1] = nBE
//	tw[2] = nCE
//	tw[3] = nDE
//	tw[4] = nEE
//	tw[5] = nFE
//	tw[6] = nGE
//	tw[7] = nHE
//	tw[8] = nIE
//	tw[9] = nJE
//	sort /A tmpsortwave tmpsortwave 
//	do 
//		r+= 1
//	while (tw[r] == -1) 
	
//	nAE = r > 9 ? -1 : tw[r ]
//	nBE = r +1 > 9 ? -1 : tw[r + 1 ]
//	nCE = r + 2> 9 ? -1 : tw[r + 2]
//	nDE = r + 3> 9 ? -1 : tw[r + 3]
//	nEE = r + 4> 9 ? -1 : tw[r + 4]
//	nFE = r + 5> 9 ? -1 : tw[r + 5]
//	nGE = r + 6> 9 ? -1 : tw[r + 6]
//	nHE = r + 7> 9 ? -1 : tw[r + 7]
//	nIE = r + 8> 9 ? -1 : tw[r + 8]
//	nJE = r + 9> 9 ? -1 : tw[r + 9]

	
//	WaveStats /Q /R = (nAE - 0.25, nAE + 0.25), $CurrentWaveName
//	nAI = v_avg
	
//	if (nBE != -1)
//		WaveStats /Q /R = (nBE - 0.25, nBE + 0.25), $CurrentWaveName
//	nBI = v_avg
//	endif
	
//	if (nCE != -1)
//		WaveStats /Q /R = (nCE - 0.25, nCE + 0.25), $CurrentWaveName
//	nCI = v_avg
//	endif
	
//	if (nDE != -1)
//		WaveStats /Q /R = (nDE - 0.25, nDE + 0.25), $CurrentWaveName
//	nDI = v_avg
//	endif
	
//	if (nEE != -1)
//		WaveStats /Q /R = (nEE - 0.25, nEE + 0.25), $CurrentWaveName
//	nEI = v_avg
//	endif
	
//	if (nFE != -1)
//		WaveStats /Q /R = (nFE - 0.25, nFE + 0.25), $CurrentWaveName
//	nFI = v_avg
//	endif
	
//	if (nGE != -1)
//		WaveStats /Q /R = (nGE - 0.25, nGE + 0.25), $CurrentWaveName
//	nGI = v_avg
//	endif
	
//	if (nHE != -1)
//		WaveStats /Q /R = (nHE - 0.25, nHE + 0.25), $CurrentWaveName
//	nHI = v_avg
//	endif
	
//	if (nIE != -1)
//		WaveStats /Q /R = (nIE - 0.25, nIE + 0.25), $CurrentWaveName
//	nII = v_avg
//	endif
	
//	if (nJE != -1)
//		WaveStats /Q /R = (nJE - 0.25, nJE + 0.25), $CurrentWaveName
//	nJI = v_avg
//	endif

		
//	string windowname = ""
//	String BacklineName
//	String WaveNameWOBkgr
	
//	if (BackType == 1) // line
//		BacklineName="background"
//		WaveNameWOBkgr=CurrentWaveName+"_wobgr"
//		WaveNameWOBkgr = XPSFit_CheckWaveName(WaveNameWOBkgr)
	
		
//		make /O /n=(DimSize($CurrentWaveName,0)) $BackLineName
//		SetScale /I x leftx($CurrentWaveName), rightx($CurrentWaveName)-deltax($CurrentWaveName), $BackLineName
//		wave wBackLineName = $(BackLineName)
//		wBackLineName=BackLine(nAE, nAI, nBE, nBI)
//		make /O /n=(DimSize($CurrentWaveName,0)) $WaveNameWOBkgr
//		SetScale /I x leftx($CurrentWaveName), rightx($CurrentWaveName)-deltax($CurrentWaveName), $WaveNameWOBkgr
//		wave wWaveNameWOBkgr = $(WaveNameWOBkgr)
///		wWaveNameWOBkgr=WaveSub($CurrentWaveName,$BackLineName)
//	/	if (cmpstr(WaveList(BackLineName, "","WIN:"), BackLineName)!=0)
//			//print "yes"
//		endif
//		if (ShowRes)
//			WindowName=WinName(0,1)
//			doWindow /F $WindowName
//			if (cmpstr(WaveList(BackLineName, "","WIN:"), BackLineName)!=0)
//				AppendToGraph $BackLineName
//			endif
//			if (cmpstr(WaveList(WaveNameWOBkgr, "","WIN:"), WaveNameWOBkgr)!=0)
//				AppendToGraph $WaveNameWOBkgr
//			endif
//		endif
//		silent 0
//	endif
	
//	if (BackType == 3) // no back
//		WaveNameWOBkgr=CurrentWaveName
//		SetScale /I x leftx($CurrentWaveName), rightx($CurrentWaveName)-deltax($CurrentWaveName), $WaveNameWOBkgr
//	endif
	
//	if (BackType == 0) // shirley
//		if (ShowRes)
//			WindowName=WinName(0,1)
//			doWindow /F $WindowName
//			//print CurrentWaveName
//			ShirleyBE(CurrentWaveName, "background",nAE, nBE, nCE, nDE, nEE, nFE, nGE, nHE, nIE, nJE , nAI, nBI, nCI, nDI, nEI, nFI, nGI, nHI, nII, nJI ,"yes","yes")
//		else
//			ShirleyBE(CurrentWaveName, "background",nAE, nBE, nCE, nDE, nEE, nFE, nGE, nHE, nIE, nJE , nAI, nBI, nCI, nDI, nEI, nFI, nGI, nHI, nII, nJI, "yes","no")
//		endif
//		silent 0
		
//	endif
	
//	if (BackType == 2 || BackType == 4) // wave, 2 - div, 4 - sub
//		BacklineName="background"
//		WaveNameWOBkgr=CurrentWaveName+"_wobgr"
//		
		
//		WaveNameWOBkgr = XPSFit_CheckWaveName(WaveNameWOBkgr)
//			//print CurrentWaveName, sBWave
//		duplicate /O  $CurrentWaveName $WaveNameWOBkgr
//		//print WaveNameWOBkgr 
//		wave wWaveNameWOBkgr = $(WaveNameWOBkgr)
//		
//		if (BackType == 2) // div
//			wWaveNameWOBkgr=WaveDiv($CurrentWaveName,$sBWave)
//		endif
		
//		if (BackType == 4) // sub
//			wWaveNameWOBkgr=WaveSub($CurrentWaveName,$sBWave)
//		endif
//		
//		if (ShowRes)
//			WindowName=WinName(0,1)
//			doWindow /F $WindowName
//			
//			if (cmpstr(WaveList(sBWave, "","WIN:"), sBWave)!=0)
//				AppendToGraph $sBWave
//			endif
			
//			if (cmpstr(WaveList(WaveNameWOBkgr, "","WIN:"), WaveNameWOBkgr)!=0)
//				AppendToGraph $WaveNameWOBkgr
//			endif
//			
//		endif
		
//		silent 0
///	endif
//end

//function BackLine(X1,Y1,X2,Y2)
//Variable X1,Y1,X2,Y2
//Variable a=(Y1-Y2)/(X1-X2)
//Variable b=Y1-a*X1
//return a*x+b
//end

//function WaveSub(wavea,waveb)
//Wave wavea, waveb
//return wavea(x)-waveb(x)
//end

//function WaveDiv(wavea,waveb)
//Wave wavea, waveb
//return wavea(x)/waveb(x)
//end
//_________________________________________________________________

function / wave XPSFit_Back(w, nBackType, sBackWave, nAE, nBE, nCE, nDE, nEE, nFE, nGE, nHE, nIE, nJE)	
	wave w
	variable nBackType
	string sBackWave
	variable nAE, nBE, nCE, nDE, nEE, nFE, nGE, nHE, nIE, nJE

	NVAR nAverXwidth = root:XPS_QuickFileViewer:g_nAverageXwidth

	duplicate /O w 'background'
	wave wBack = $("background")
	
	variable nNumRegs = 0
	if (nAE != inf)
		nNumRegs += 1
	endif
	if (nBE != inf)
		nNumRegs += 1
	endif
	if (nCE != inf)
		nNumRegs += 1
	endif
	if (nDE != inf)
		nNumRegs += 1
	endif
	if (nEE != inf)
		nNumRegs += 1
	endif
	if (nFE != inf)
		nNumRegs += 1
	endif
	if (nGE != inf)
		nNumRegs += 1
	endif
	if (nHE != inf)
		nNumRegs += 1
	endif
	if (nIE != inf)
		nNumRegs += 1
	endif
	if (nJE != inf)
		nNumRegs += 1
	endif
	
	variable nLowX = leftx(w)
	variable nHighX = rightx(w) - deltax(w)
	
	if (nLowX > nHighX)
		variable ntemp = nLowX
		nLowX = nHighX
		nHighX = ntemp
	endif
	
	WaveStats /Q /R = (nLowX-nAverXwidth/2, nLowX + nAverXwidth/2 ) w
	variable nLowY = v_avg
	WaveStats /Q /R = (nHighX-nAverXwidth/2, nHighX + nAverXwidth/2 ) w
	variable nHighY = v_avg
	
	wBack = nLowY
	
	if (nNumRegs < 2)
		nAE = nLowX
		nBE = nHighX
		nNumRegs = 2
	endif

	variable idx, e, i, a, b
	variable nNumIts = 5
	string sSortPos = sortList(num2str(nAe) + ";" + num2str(nBe) + ";" + num2str(nCe) + ";" + num2str(nDe) + ";" + num2str(nEe) + ";" + num2str(nFe) + ";" + num2str(nGe) + ";" + num2str(nHe) + ";" + num2str(nIe) + ";" + num2str(nJe) + ";", ";",4)
	
	variable nLowestX =  nLowX
	variable nHighestX = nHighX
		
	for (idx = 0; idx < nNumRegs-1; idx += 1)
		nLowX = str2num(stringfromlist(idx,sSortPos)) 
		nHighX = str2num(stringfromlist(idx + 1,sSortPos)) 
		
		WaveStats /Q /R = (nLowX-nAverXwidth/2, nLowX + nAverXwidth/2 ) w
		nLowY = v_avg
		WaveStats /Q /R = (nHighX-nAverXwidth/2, nHighX + nAverXwidth/2 ) w
		nHighY = v_avg
		
		a = (nLowY-nHighY)/(nLowX-nHighX)
		b = nLowY-a*nLowX
	
		switch (nBackType)
			case SHIRLEY: // shirley
				for (i = 0; i < nNumIts; i += 1)
					for (e = nLowX; e <= nHighX + abs(deltax(wback)) ; e += abs(deltax(wback)))	
						wBack[x2pnt(wback,e)] = nLowY + (nHighY - nLowY) * (Area(w,nLowX,e) - Area (wBack, nLowx, e))/ (Area(w,nLowx,nHighX) - Area (wBack, nLowx, nHighX))
					endfor
				endfor
				break
	
			case LINEAR: // linear
				for (e = nLowX; e <= nHighX + abs(deltax(wback)) ; e += abs(deltax(wback)))	
					wBack[x2pnt(wback,e)] = a * e + b
				endfor
				break
		endswitch
			
	endfor

	nLowX = str2num(stringfromlist(0,sSortPos))
	nHighX = str2num(stringfromlist(1,sSortPos))
	
	WaveStats /Q /R = (nLowX-nAverXwidth/2, nLowX + nAverXwidth/2 ) w
	nLowY = v_avg
	WaveStats /Q /R = (nHighX-nAverXwidth/2, nHighX + nAverXwidth/2 ) w
	nHighY = v_avg
		
		
	
	if (nLowX != nLowestX )
		switch (nBackType)
			case SHIRLEY:
				wBack[min(x2pnt(wBack,nLowX), x2pnt(wBack,nLowestX)),max(x2pnt(wBack,nLowX), x2pnt(wBack,nLowestX))] = w(nLowX)
				break
				
			case LINEAR:
				a = (nLowY-nHighY)/(nLowX-nHighX)
				b = nLowY-a*nLowX
				wBack[min(x2pnt(wBack,nLowX), x2pnt(wBack,nLowestX)),max(x2pnt(wBack,nLowX), x2pnt(wBack,nLowestX))] = a*x+b
				break
		endswitch
	endif
	
	nLowX = str2num(stringfromlist(idx - 1,sSortPos))
	nHighX = str2num(stringfromlist(idx,sSortPos))
	WaveStats /Q /R = (nLowX-nAverXwidth/2, nLowX + nAverXwidth/2 ) w
	nLowY = v_avg
	WaveStats /Q /R = (nHighX-nAverXwidth/2, nHighX + nAverXwidth/2 ) w
	nHighY = v_avg
	
	if (nHighX != nHighestX)
		switch(nBackType)
			case SHIRLEY:
				wBack[min(x2pnt(wBack,nHighX), x2pnt(wBack,nHighestX)),max(x2pnt(wBack,nHighX), x2pnt(wBack,nHighestX))] = w(nHighX)
				break
			
			case LINEAR:
				a = (nLowY-nHighY)/(nLowX-nHighX)
				b = nLowY-a*nLowX
				wBack[min(x2pnt(wBack,nhighX), x2pnt(wBack,nhighestX)),max(x2pnt(wBack,nhighX), x2pnt(wBack,nhighestX))] = a*x+b
				break
		endswitch

	endif

	return wBack
end




// analyze (correct energy scale, subtract background) one wave
function Analyze1DWave (s_WName, s_EnergyType, s_BackType, sBckgWave,nEnergy, nAE, nBE, nCE, nDE, nEE, nFE, nGE, nHE, nIE, nJE )
	String s_WName, s_EnergyType, s_BackType, sBckgWave
	Variable nEnergy,nAE, nBE, nCE, nDE, nEE, nFE, nGE, nHE, nIE, nJE

	//NVAR gEFermi = root:XPS_QuickFileViewer:g_EFermi
	Variable i = 0;
	//String s_WName= 
	silent 1;
	
	if (stringmatch(s_EnergyType, "Kinetic energy"))
		nAE = nAE == -1? -1 : nEnergy - nAE 
		nBE = nBE == -1? -1 : nEnergy - nBE 
		nCE = nCE == -1? -1 : nEnergy - nCE 
		nDE = nDE == -1? -1 : nEnergy - nDE 
		nEE = nEE == -1? -1 : nEnergy - nEE 
		nFE = nFE == -1? -1 : nEnergy - nFE 
		nGE = nGE == -1? -1 : nEnergy - nGE 
		nHE = nHE == -1? -1 : nEnergy - nHE 
		nIE = nIE == -1? -1 : nEnergy - nIE 
		nJE = nJE == -1? -1 : nEnergy - nJE 			
	endif
	//print s_WName,nEnergy, nAE, nBE, nCE, nDE, nEE, nFE, nGE, nHE, nIE, nJE
	//return 0
	//do 
	//	s_WName = StringFromList(i,sListOfWaves);
		//if (strlen(s_WName) == 0) 
		//	break;
		//endif
		
//		if (stringmatch(s_EnergyType, "Kinetic energy"))
//			EToBE(s_WName,"Kinetic energy",0, nEnergy); // reverse KE scale and normalize			
//		endif
	
//		if (stringmatch(s_EnergyType, "Binding energy"))
//			EToBE(s_WName ,"Binding energy",0, nEnergy) ; //BE 
//		endif
		
		if (stringmatch (s_BackType, "Shirley"))
//			SubBack(s_WName ,0,0,"", nAE, nBE, nCE, nDE, nEE, nFE, nGE, nHE, nIE, nJE ); // 1 : lin; 0: shi
		endif
		
		if (stringmatch (s_BackType, "Linear"))
//			SubBack(s_WName,0,1,"",nAE, nBE, nCE, nDE, nEE, nFE, nGE, nHE, nIE, nJE ); // 1 : lin; 0: shi
		endif
		
		if (stringmatch(s_BackType, "From wave div"))
//			SubBack( s_WName,0,2, sBckgWave, nAE, nBE, nCE, nDE, nEE, nFE, nGE, nHE, nIE, nJE ) // 1 : lin; 0: shi
		endif
		
		if (stringmatch(s_BackType, "From wave sub"))
//			SubBack( s_WName,0,4, sBckgWave, nAE, nBE, nCE, nDE, nEE, nFE, nGE, nHE, nIE, nJE ) // 1 : lin; 0: shi
		endif
		
		if (stringmatch(s_BackType, "None"))
//			SubBack( s_WName,0,3, "",nAE, nBE,-1,-1,-1,-1,-1,-1,-1,-1) // 1 : lin; 0: shi
		endif
		
		i+=1;
	//while (1);
	
	silent 0;
end
//_________________________________________________________________
function /S XPSFit_LoadSpecsXMLReturnName (sName)
	string sName
		
	variable idx
	string s
		
	for (idx = strlen(sName) - 1; idx > 1; idx -= 1)
		//print sName[idx], sName[idx-1]
		if((char2num(sName[idx])>=48 && char2num(sName[idx]) <= 57) &&(char2num(sName[idx-1])>=48 && char2num(sName[idx-1]) <= 57))
			return sName[0,idx]
		else
			XPSFit_LoadSpecsXMLReturnName(sName[0,idx-1])
		endif
	endfor
	
	return sName
	
end

//______________________________________________________________________________________

 function /S XPSFit_LoadSpecsXMLText(sFileToLoad, sFileFolderPath)
	String sFileToLoad, sFileFolderPath
	
	PauseUpdate
	NVAR bOverWriteWave = root:XPS_QuickFileViewer:g_bOverWriteWave
	NVAR bKeepSwepsXML = root:XPS_QuickFileViewer:g_bKeepSwepsXML
	NVAR bLoadTimeDate = root:XPS_QuickFileViewer:g_bLoadTimeDate
	NVAR bUseFileName = root:XPS_QuickFileViewer:g_bUseFileName
	
	LoadWave /J/O/K=2/B="N=TempWaveALSXML;" /A (sFileFolderPath +sFileToLoad)
	variable nTempWaveL = DimSize(TempWaveALSXML,0)
	wave/T wTempWaveALS = $("TempWaveALSXML")
	
	variable i = 0, idx = 0, j = 0, t = 0, k = 0, l = 0, n
	variable nNumChan = 9
	variable nPE = 10
	variable ndPE = 0
	make /O /N = (nNumChan) wChanShift
	wave wChanShift = $("wChanShift")
	make /O /N = (nNumChan) wChanGain
	wave wChanGain = $("wChanGain")
	string str
	string sRegName, sRegNum, sWaveName
	variable nPosLast
	variable nNumPnts, nDelta, nLKE, nRKE, nRegNum, nSum, nDwellTime, nNumScans, nTime
	
	if(bUseFileName)
		string sWNameBase = sFileToLoad [0,strlen(sFileToLoad) - 5] + "_"
	else
		sWNameBase = ""
	endif
	
	string sListLoadWaves =""
	
	do
		str = wTempWaveALS[i] 
		if (stringmatch(str,"*\"RegionData\"*")) // if line contains "RegionData"
			if (strlen(sRegNum))
				string sWName =  XPSFit_CheckWaveName(sWNameBase + sRegNum)
				string sListWaves = ""
				for (n = 0; n < l; n+= 1)
					sListWaves += sWName + "_" + num2str(n) + ";"
				endfor
			//print sListWaves
			endif
			if (strlen(sListWaves))
				XPSFit_WaveArithm(sListWaves,ARITHM_AVERAGE,"0",0)
				sListLoadWaves += sWName + ";"
				
				if (!waveexists($sWName) || bOverWriteWave)
					//abort
					if(itemsinlist(sListWaves) == 1)
						duplicate /O $(sWName + "_0" ) $sWName
					else	
						duplicate /O $(sWName + "_0_avg" ) $sWName
					endif
					
					if (!bKeepSwepsXML)
						for (k = 0; k < itemsinlist(sListWaves); k += 1)
							KillWaves $(StringFromList(k,sListWaves))
						endfor
					endif
				else 
					for (k = 0; k < itemsinlist(sListWaves); k += 1)
						KillWaves $(StringFromList(k,sListWaves))
					endfor	
				
				endif
				
				
				
				KillWaves /Z $(sWName + "_0_avg" )
				//abort
			endif
			l = 0
			
			i += 1
			str = wTempWaveALS[i] 
			nPosLast = strsearch(str, "</string>",0)
			sRegName = str[20,nPosLast-1]
			sRegName = XPSFit_LoadSpecsXMLReturnName(sRegName)
			sRegNum = sRegName[strlen(sRegName) - 4, strlen(sRegName )- 1] 
			if (cmpstr(sRegNum[0], "_") == 0 || cmpstr(sRegNum[0], " ") == 0)
				sRegNum = sRegNum[1,3]
			endif
			nRegNum = str2num(sRegNum)
			
		
		
			
			
			print sRegName
			t=  0
			
		endif
		
		if (stringmatch(str,"*num_scans*"))
			nPosLast = strsearch(str, "</ulong>",0)
			nNumScans = str2num(str [24,nPosLast-1])
		endif
		
		
		if (stringmatch(str,"*\"detectors\"*"))
			nPosLast = strsearch(str, "type_id",0)
			nNumChan = str2num(str [35,nPosLast-3])
			redimension /N= (nNumChan) wChanShift
			redimension /N= (nNumChan) wChanGain

		endif
		
		if (stringmatch(str,"*values_per_curve*")) // if line contains "values_per_curve"
			nPosLast = strsearch(str, "</ulong>",0)
			nNumPnts = str2num(str [31,nPosLast-1])
			//print nNumPnts
		endif
		
		if (stringmatch(str,"*dwell_time*")) // if line contains "dwell_time"
			nPosLast = strsearch(str, "</double>",0)
			nDwellTime = str2num(str [26,nPosLast-1])
		endif
		
		if (stringmatch(str,"*scan_delta*")) // if line contains "scan_delta"
			nPosLast = strsearch(str, "</double>",0)
			nDelta = str2num(str [26,nPosLast-1])
			
		endif
		
		if (stringmatch(str,"*kinetic_energy*") && !stringmatch(str,"*kinetic_energy_base*")) // if line contains "scan_delta"
			nPosLast = strsearch(str, "</double>",0)
			//print str
			nLKE = str2num(str [30,nPosLast-1])
			nRKE = nLKE + (nNumPnts - 1) * nDelta		
		endif
		
		if (stringmatch(str,"*pass_energy*")) // if line contains "pass_energy"
			nPosLast = strsearch(str, "</double>",0)
			nPE = str2num(str [27,nPosLast-1])
			
		endif
		
		
		if (stringmatch(str,"*\"Detector\"*")) // if line contains "scan_delta"
			if(stringmatch(wTempWaveALS[i+1] ,"*shift*"))
				i += 1
			elseif(stringmatch(wTempWaveALS[i+2] ,"*shift*"))
				i += 2
			endif
			
			str = wTempWaveALS[i] 
		//	print str
			nPosLast = strsearch(str, "</double>",0)
			wChanShift[t] = str2num(str[21,nPosLast-1])
			str = wTempWaveALS[i+1] 
			nPosLast = strsearch(str, "</double>",0)
			wChanGain[t] = abs(str2num(str[20,nPosLast-1]))
			t += 1
			//print wChanShift[t]
		endif
		
		if (stringmatch(str,"*ulong name=\"time\"*")) // if line contains "time"
			//print str
			nTime = str2num(str[19,strsearch(str,"</ulong>",0) -1])
			if (bLoadTimeDate)
				print secs2date(nTime,0), secs2time(nTime,1)
			endif
		endif
		
		
		if (stringmatch(str,"*type_name=\"Counts\"*")) // if line contains "counts"
			i += 1
			nDPE = floor((wChanShift[nNumChan - 1] - wChanShift[0]) / nDelta * nPE )
			//print nNumPnts, nDPE
			nNumPnts += nDPE
			sWaveName = XPSFit_CheckWaveName(sWNameBase + sRegNum + "_" + num2str(l))
			
			if (!waveexists($sWaveName))
				
				for (k = 0; k < nNumChan; k += 1)
					make /O /N=(nNumPnts) $(sWaveName + "_" +num2str(k))
					
					wave w = $(sWaveName + "_" +num2str(k))
					
					for (idx = k; idx < nNumPnts * nNumChan; idx += nNumChan)
						str = wTempWaveALS[i + idx]
						w[floor(idx / nNumChan)] = str2num(str) 
					endfor
					w *= wChanGain[k]
					setscale /P x  nLKE + (wChanShift[k] - wChanShift[nNumChan])* nPE,  nDelta, $(sWaveName + "_" +num2str(k))
				endfor
				
			
				make /O /N=(nNumPnts - nDPE) $sWaveName
				wave wWave = $sWaveName
				wWave = 0
				setscale /P x pnt2x(w,0), nDelta , $sWaveName 
				
				for (k = 0; k < nNumChan; k += 1)
					wave w = $(sWaveName + "_" +num2str(k))
					wWave = wWave(x) + w(x)
					KillWaves $NameOfWave(w)
				endfor
				wWave /= nDwellTime
			else
				idx =  nNumPnts * nNumChan
				
			endif	
			i+= 1
			t = 0
			l+= 1
			nNumPnts -= nDPE
//			print sRegName, nRegNum, nDelta, nLKE, nRKE, nNumPnts, nNumScans, l
			
		endif
		
		

		i += 1
	while (i < nTempWaveL)
	
	KillWaves $("wChanShift"), $("wChanGain"), $("TempWaveALSXML")
	
	 sWName =  XPSFit_CheckWaveName(sWNameBase + sRegNum)
			 sListWaves = ""
			for (n = 0; n < l; n+= 1)
			sListWaves += sWName + "_" + num2str(n) + ";"
			endfor
			//print sListWaves
			
			if (strlen(sListWaves))
				XPSFit_WaveArithm(sListWaves,ARITHM_AVERAGE,"0",0)
				
				if (!waveexists($sWName) || bOverWriteWave)
					if(itemsinlist(sListWaves) == 1)
						duplicate /O $(sWName + "_0" ) $sWName
					else	
						duplicate /O $(sWName + "_0_avg" ) $sWName
					endif
				endif
				if (!bKeepSwepsXML)
					for (k = 0; k < itemsinlist(sListWaves); k += 1)
						//print (StringFromList(k,sListWaves)), (sWName + "_0_aver" ) 
						//if (waveexists ($StringFromList(k,sListWaves)))
						KillWaves $(StringFromList(k,sListWaves))
					//endif
					endfor
				endif
				//print sWName + "_0_aver"
				KillWaves /Z $(sWName + "_0_avg" )
				//abort
			endif
			l = 0
	
			return sListLoadWaves
	
end

//____________________________________________________________
// loads data saved in specs xy

function /S XPSFit_LoadSpecsText(sFileToLoad, sFileFolderPath)
	String sFileToLoad, sFileFolderPath
	
	NVAR bOverWriteWave = root:XPS_QuickFileViewer:g_bOverWriteWave
	
	//String Wave_columnStrInfo="", TempWaveName="",TempWaveNameKE=""
	//make /O/T/N=1000 wNames // wave for all wave names
	//LoadWave /J/O/K=2/B="N=TempWaveALS;" /A (sFileFolderPath +sFileToLoad)// load all data in one wave, including region info
	
	string sFileList = XPSFit_LoadALSMakeList( sFileToLoad, sFileFolderPath) // makes list of all regions saved in xml

//	NewPath /O F_Path, S_path 
	LoadWave /G/O/N=TempWave /Q (sFileFolderPath +sFileToLoad) // load just numerical data
	
	//String s_Wave_w_name = ""
	//Variable nWave_w_energies = 0
	//String sNewWaveName
	//Variable count=1
	//TempWaveName="TempWave"+num2str(count)
	//TempWaveNameKE="TempWave"+num2str(count-1)
	
	string sName
	variable idx
	for (idx = 0; idx < ItemsInList(sFileList); idx += 1)
		sName = StringFromList(idx,sFileList)
		wave w = $("TempWave" + num2str(idx * 2+1))
		wave wE = $("TempWave" + num2str(idx * 2 ))
		
		if (bOverWriteWave || !WaveExists($StringFromList(idx, sFileList)))
			Duplicate /O w, $sName
			SetScale /I x, wE[0], wE[numpnts(wE)-1], $sName
		endif
		KillWaves w, wE
	endfor
	return sFileList
end
	
	
//	do // go through the list of all waves
//		NewWaveName = Wave_w_names[(count-1)/2]
//		 if (!WaveExists($NewWaveName))	 // if a wave with such name already exists skip next
//			//print TempWaveName,TempWaveNameKE,NewWaveName
//			s_Wave_w_name += WaveRenameON($TempWaveName,TempWaveNameKE,NewWaveName) + ";"// give temporary wave a real name
//		endif
//		KillWaves $TempWaveName, $TempWaveNameKE // delete temporary wave
//		count+=2 // take next temp wave
//		TempWaveName="TempWave"+num2str(count)
//		TempWaveNameKE="TempWave"+num2str(count-1)
	
//	while (WaveExists($TempWaveName))
//	silent 0
//	return s_Wave_w_name
//end



//gets info about all region names saved in SPECS xy

function/s XPSFit_LoadALSMakeList(sFileToLoad, sFileFolderPath)
	String sFileToLoad, sFileFolderPath
	
	NVAR bUseFileName = root:XPS_QuickFileViewer:g_bUseFileName
	
	LoadWave /Q/J/O/K=2/N=TempWaveALS /A (sFileFolderPath +sFileToLoad)// load all data in one wave, including region info
	
	if(bUseFileName)
		string sBaseName = s_fileName[0,strsearch(s_fileName,".",strlen(s_fileName)-1,3) - 1]
	else 
		sBaseName = ""
	endif
	
	string sFileList = ""
	wave /T TempWaveALS0
	//make /O/N=0 wALSWaveList
	
	
	
	
//	String TempStr="",TempStrEnd=""//, TempStrEnergy = "" // 
//	Variable Wave_num_pts=numpnts(TempWaveALS) // number of points in wave with all data
//	Variable C_number=0,count=0, count_1 = 0
//	String NewWaveName
//	String letter
	
	string s, sRegNum
	variable nRegNumPos
	variable nLen = numPnts(TempWaveALS0)
	
	variable idx = 0

	do
		s = TempWaveALS0[idx]
		if (stringmatch(s, "*Region*"))
			sRegNum =  XPSFit_GetSepStr(s, "_;.; ;",1,1)
			//sRegNum = s[nRegNumPos + 1, strlen(s) - 1]
			//Redimension /N = (DimSize(wALSWaveList,0) + 1) wALSWaveList
			sFileList += XPSFit_CheckWaveName(sBaseName + sRegNum) + ";"
		endif
		idx += 1
	while (idx < nLen)
	
	
	string sList =WaveList("TempWaveALS*",";","") 
	for (idx = 0; idx < itemsinlist(sList); idx += 1)
		//KillWaves $StringFromList(idx, sList)
	endfor

	return sFileList
	
	
	
	
//	for (idx;C_number<=Wave_num_pts;C_number+=1)
//		TempStr=TempWaveALS[C_number] // get content of c_number cell of wave with all data
//		if (stringmatch(TempStr,"*Region:*")) // if this cell has Region: then it is region name
//			TempStrEnd=TempStr[strlen(TempStr)-4,strlen(TempStr)] // cut last 4 digits from the region name. they will be region number
//			if (char2num(TempStrEnd[0]) > 57 || char2num(TempStrEnd[0]) <48) // remove first letter if it is not a number
//				TempStrEnd = TempStrEnd [1,strlen(TempStrEnd) - 1]
//			endif
//			NewWaveName = S_fileName[0,strlen(S_fileName)-4]+"_" // first part of wave name is file name
//			NewWaveName +=  TempStrEnd  // add only number to the end of wave name
//			NewWaveName = XPSFit_CheckWaveName(NewWaveName) // check whether first letter of wave is a letter, not a number
//			Wave_w_names[count] = NewWaveName // fill a cell with a wave name
//			count+=1 // prepare next cell from  Wave_w_names and Wave_w_energies 
///		endif
//	endfor
	
//	killwaves TempWaveALS // kill unnesessary wave
//	return "OK"
	
end
//________________________________________________________________

// removes traces from top graph according to chosen mode

function RemoveTracesFromWnd(nWhatRemove)
	Variable nWhatRemove 
	
	Variable v_max,v_min
	
	GetAxis bottom
	Variable x_min = min(v_min,v_max)
	Variable x_max = max(v_min,v_max)
	GetAxis left
	Variable y_min = min(v_min, v_max) 
	Variable y_max = max(v_min,v_max)
	Variable idx = 0
//	String sWaveName
	String sWaveList = TraceNameList("",";",1)
	if (strlen(sWaveList))
		do 
			string sWaveName = StringFromList (idx,sWaveList)			
			
			if (strlen(sWaveName) == 0)
				break
			endif

			Wave wWaveName = TraceNameToWaveRef("",sWaveName)
			Wave/Z wXWaveName = XWaveRefFromTrace("",sWaveName)
			
			if (IsWaveInsideWindow(wWaveName,wXWaveName,x_min,x_max, y_min, y_max) == nWhatRemove)
				RemoveFromGraph $sWaveName
			endif
			idx += 1
		while(1)
	endif
end

function IsWaveInsideWindow(wWaveName,wXWaveName,x_min,x_max,y_min,y_max)
	Wave/Z wWaveName, wXWaveName
	Variable x_min,x_max,y_min,y_max

	Variable I_min = XPSGetMin(wWaveName)
	Variable I_max = XPSGetMax(wWaveName)
	Variable E_min, E_max
	
	if(waveExists(wXWaveName))
		E_min = Min(wXWaveName[0], wXWaveName[numpnts(wXWaveName) - 1])
		E_max = Max(wXWaveName[0], wXWaveName[numpnts(wXWaveName) - 1])
	else
		E_min = pnt2x(wWaveName,0) > pnt2x(wWaveName,numpnts(wWaveName)-1) ? pnt2x(wWaveName,numpnts(wWaveName)-1) : pnt2x(wWaveName,0)
		E_max = pnt2x(wWaveName,0) > pnt2x(wWaveName,numpnts(wWaveName)-1) ? pnt2x(wWaveName,0) : pnt2x(wWaveName,numpnts(wWaveName)-1)
	
	endif
	
	variable i = 0
	variable isIn = 0
	
	if (x_min <= E_min && x_max >= E_max && y_min <= I_min && y_max >= i_max)
		return 1
	else 
		for (i = 0; i < numpnts(wWaveName) - 1; i += 1)
			if (point2x(wWaveName,wXWaveName,i) > x_min && point2x(wWaveName,wXWaveName,i) < x_max && wWaveName[i] > y_min && wWaveName[i] < y_max)
				return -1
			endif
		endfor
		return 0
	endif
end

function point2x(wY, wX, nP)
	wave /Z wY, wX
	variable nP
	
	if(waveExists(wX))
		return wX[nP]
	else
		return(pnt2x(wY,nP))
	endif
end

function XPSGetMin (wWaveName)
	wave wWaveName
	variable i = 0;
	variable v_min = wWaveName[0]
	for (i = 1; i < numpnts(wWaveName) - 1; i+=1)
		v_min = v_min < wWaveName[i] ? v_min : wWaveName[i] 
	endfor
	return v_min
end

function XPSGetMax(wWaveName)
	wave wWaveName
	variable i = 0;
	variable v_max = wWaveName[0]
	for (i = 1; i < numpnts(wWaveName) - 1; i+=1)
		v_max = v_max > wWaveName[i] ? v_max : wWaveName[i] 
	endfor
	return v_max
end
//___________________________________________________________________________________

// converts list of 1D waves (from top graph) to matrix. Clever function: cuts energies if spectra have different energy scales

function procMakeMatrix(ctrlName) : ButtonControl
	String ctrlName
	
	XPSFit_MakeMatrixFunk()
end

function /S XPSFit_MakeMatrixFunk ()
	
	SVAR sMakeMatrixMethod = root:XPS_QuickFileViewer:g_sMakeMatrixMethod
	
	String sCurDataFolder = GetDataFolder(1)
	 string s_ListOfWaves = SortList(TraceNameList("", ";",1),";",16);
	
	if (strlen(s_ListOfWaves) == 0) 
		abort "No waves"
	endif
	
	String sRes = XPSFit_MakeMatrix(s_ListOfWaves,sMakeMatrixMethod)
	
	XPSFit_DisplayResults(sRes)
	
	SetDataFOlder(sCurDataFolder)
end


function /S XPSFit_MakeMatrix(s_ListOfWaves, sMakeMatrixMethod)
	string s_ListOfWaves, sMakeMatrixMethod
	
	//print s_ListOfWaves
	SVAR sgMakeMatrixMethod = root:XPS_QuickFileViewer:g_sMakeMatrixMethod
	
	if (!strlen(sMakeMatrixMethod))
		sMakeMatrixMethod = sgMakeMatrixMethod
	endif
	
	String sMatrixWaveName = StringFromList(0,s_ListOfWaves) + "_M"
	print sMatrixWaveName
	Variable wNum = 0;
	wNum = ItemsInList (s_ListOfWaves)
	Variable idx = 0
	Variable nLowBE, nHighBE
	Variable nLowMatrixBE = rightx($(stringfromlist(0,s_ListOfWaves)))- deltax($(stringfromlist(idx,s_ListOfWaves)))
	Variable nHighMatrixBE =  leftx($(stringfromlist(0,s_ListOfWaves))) 
	//print nLowMatrixBE, nHighMatrixBE
	if (nHighMatrixBE < nLowMatrixBE)
		Variable temp = nHighMatrixBE
		nHighMatrixBE = nLowMatrixBE
		nLowMatrixBE = temp
	endif
	//print nLowMatrixBE, nHighMatrixBE
	///abort
	for (idx = 0; idx < wNum; idx += 1)
		nLowBE = rightx($(stringfromlist(idx,s_ListOfWaves))) - deltax($(stringfromlist(idx,s_ListOfWaves)))
		nHighBE = leftx($(stringfromlist(idx,s_ListOfWaves))) 
		
		if(nLowBE > nHighBE)
			nLowBE += nHighBE
			nHighBE = nLowBE - nHighBE
			nLowBE -= nHighBE
		endif
		
		if(stringmatch(sMakeMatrixMethod, "Truncate")) // cut
			nLowMatrixBE = nLowMatrixBE > nLowBE ?  nLowMatrixBE :  nLowBE
			nHighMatrixBE = nHighMatrixBE < nHighBE ? nHighMatrixBE : nHighBE
		elseif(stringmatch(sMakeMatrixMethod,"Extend"))
		
			nLowMatrixBE = nLowMatrixBE < nLowBE ?  nLowMatrixBE :  nLowBE
			nHighMatrixBE = nHighMatrixBE > nHighBE ? nHighMatrixBE : nHighBE
		endif
		
		//print nLowBE, nHighBE
		
		
	endfor
	
	//print nLowMatrixBE, nHighMatrixBE
	//abort
	Variable nNumPts = (x2pnt($(stringfromlist(0,s_ListOfWaves)),nLowMatrixBE)) - (x2pnt($(stringfromlist(0,s_ListOfWaves)),nHighMatrixBE)) 
	nNumPts = nNumPts > 0 ? nNumPts + 1: -nNUmPts + 1
	//print nNumPts
	make /O/N = (nNumPts,wNum) $(sMatrixWaveName)
	
	wave wMatrixWaveName = $(sMatrixWaveName)
	SetScale /I x nLowMatrixBE, nHighMatrixBE, wMatrixWaveName
	variable xBE, j
	//print sMatrixWaveName,DimOffset(wMatrixWaveName,0)
	//abort
	for (idx = 0; idx < wNum; idx += 1)
		Wave wCurWave = $(stringfromlist(idx,s_ListOfWaves))
		//Wave wCutWave = XPS_wCutWave(wCurWave,nLowMatrixBE,nHighMatrixBE)
		for (j =0; j < dimsize(wMatrixWaveName,0); j += 1)
			xBE = DimOffset(wMatrixWaveName,0) + DimDelta(wMatrixWaveName,0) * j
			wMatrixWaveName[j][idx] = wCurWave(xBE)
		
		endfor
		KillWaves /Z wCutWave	
	endfor
	
	
	return NameOfWave(wMatrixWaveName)
end

function /Wave XPS_wCutWave (wCurWave, nPosA, nPosB)
	Wave wCurWave
	Variable nPosA,nPosB

	if (nPosB > nPosA)
		Variable temp = nPosB
		nPosB = nPosA
		nPosA = temp
	endif
	Variable nPntA = x2pnt(wCurWave,nPosA)
	Variable nPntB = x2pnt(wCurWave,nPosB)
	Variable nNumOfPts = (nPntA - nPntB) > 0 ? (nPntA - nPntB) : - (nPntA - nPntB)
	nNumOfPts += 1
	Make /O /N=(nNumOfPts) $(NameOfWave(wCurWave) + "_cut")
	Wave wCutWave = $(NameOfWave(wCurWave) + "_cut")
	Variable idx = 0
	for (idx = 0; idx < nNumOfPts; idx += 1)
		wCutWave [idx] = wCurWave [(nPntA < nPntB ? nPntA : nPntB) + idx ]	
	endfor
	SetScale /I x, nPosA, nPosB, wCutWave
	return wCutWave
end
//___________________________________________________________________________

// averages list of 1D waves (plotted on the top graph)
//
//function  XPSWaveAver(ctrlName)
//	String ctrlName
//	
//	String sCurDataFolder = GetDataFolder(1)
//	String wTopWave = GetWavesDataFolder(WaveRefIndexed("",0,1),1)
//	SetDataFolder $wTopWave
//	String sWaveList = TraceNameList("",";",1)
//	if (strlen(sWaveList))
	
//		if (stringmatch(ctrlName, "AverWaves"))
//			wave wAverWave = XPSFuncAver(sWaveList,1)
//		else
//			if (stringmatch(ctrlName, "SumWaves"))
//				wave wAverWave = XPSFuncAver(sWaveList,0)
//			else
//				SetDataFOlder(sCurDataFolder)
//				return 0
//			endif
			
//		endif
		
//		string sAverName = NameOfWave(wAverWave)
//		if (strsearch(TraceNameList("",";",1),sAverName,0) == -1)
//				AppendToGraph wAverWave
//		endif
//	endif
//	
//	SetDataFOlder(sCurDataFolder)
//end
//__________________________________________________________________

//function/WAVE XPSFuncAver(sWaveList,bAver)
//	string sWaveList
//	variable bAver
//	
//	String sWaveName =""
//	variable idx = 0
	
//	if (strlen(sWaveList))
//		sWaveName = StringFromList(idx,sWaveList)
//		String sAverName 
//		if (bAver)
//			sAverName = sWaveName + "_aver"
//		else
//			sAverName = sWaveName + "_tot"
//		endif
		
//		duplicate /O $sWaveName $sAverName
//		wave wAverWave =   $sAverName
//		do 
//			idx += 1;
//			sWaveName = StringFromList(idx,sWaveList)
//			if (strlen (sWaveName))
//				wave wWaveName = $sWaveName
//				wAverWave +=	wWaveName(x)	

//			else
//				break
//			endif
//		while (1)
//		if (bAver)
//			wAverWave /= idx 
///		endif
//	endif
	
//	return wAverWave
//end
//
function /S XPSFit_GetWaveList()
	
	string sWList = ""
	string csr
	variable idx 

	if(strlen(CsrWave(A)))
		sWList = CsrWave(A) + ";"
	endif
	
	if(!strlen(sWList))
		if(strlen(ImageNameList("",";")))
			sWList = XPSFit_RemoveSWaves(ImageNameList("",";"),0, "_wobgr")
		else
			sWList = XPSFit_RemoveSWaves(TraceNameList("",";",1),0, "_wobgr")
		endif
	endif
	
	
	return sWList
end


function /S XPSFit_GetCsrWave(sCsr)
	string sCsr
	
	string sWave = csrWave($sCsr)
	
	if(!strlen(sWave))
		Abort("No " + sCsr +" cursor on Graph")
	endif

	return sWave
end


//____________________________________
function XPSFit_DisplayResults(sResWaveList)
	string sResWaveList
	
	print sResWaveList
	nvar bDisplayWArithmRes = root:XPS_QuickFileViewer:g_bDisplayWArithmRes
	nvar bAppendWArithmRes = root:XPS_QuickFileViewer:g_bAppendWArithmRes
	
	variable idx
	
	if(bAppendWArithmRes && !DimSize($(WaveName("",0,1)),1))
		for(idx = 0; idx < itemsinlist(sResWaveList); idx += 1)
			wave w = $StringFromList(idx, sResWaveList)
			if (FindListItem(NameOfWave(w), WaveList("*", ";","WIN:")) == -1 && !DimSize(w,1))
				AppendToGraph w
			endif
		endfor	
	endif	
	
	if(bDisplayWArithmRes)
		for(idx = 0; idx < itemsinlist(sResWaveList); idx += 1)
			wave w = $StringFromList(idx, sResWaveList)
			if (DimSize(w,1))
				display
				AppendImage w
			else
				//if (ItemsInlist(sResWaveList) > 1)
					if(idx == 0)
						display
					endif
					AppendToGraph w
				//endif
			endif
		endfor	
	endif

end


//==============================================================================================================================
// do various arithmetics with waves
function XPSFit_WaveArithmFunk(sCtrlName, bSingle)
	string sCtrlName
	variable bSingle
	
	string sCurFolder = GoToDataFolder()
	variable nOperation
	string sParam = ""
	
	ControlInfo SWaveArithm_C
	variable nC = v_value
	
	ControlInfo SWaveArithm_XShift
	variable nBEShift = v_value
	ControlInfo pmWArithmBinSize
	variable	nBin = str2num(s_value)
	
	variable nMode = MODE_RUNAVG
	controlInfo pmWArithmeticsBinMode
	
	// get list of waves
	string sWaveList = XPSFit_GetWaveList()

	variable idx
	
	strswitch (sCtrlName)
		case "bnWArithmNormAreas":
			nOperation = ARITHM_NORMAREAS
			break

		case "bnWArithmAverWaves" :
			nOperation = ARITHM_AVERAGE
			break
			
		case "bnSumWaves" :
			nOperation = ARITHM_SUM
			break
			
		case "bnWArithmBinHor" :
			nOperation = ARITHM_BINHOR
			sParam = num2str(nBin)
		
			if(stringmatch(s_value, "Edges"))
				nMode = MODE_EDGES	
			endif
			
			if(stringmatch(s_value, "RunAvg"))
				nMode = MODE_RUNAVG	
			endif
		
			break
			
		case "bnWArithmBinVer" :
			nOperation = ARITHM_BINVER
			sParam = num2str(nBin)
			
			if(stringmatch(s_value, "Edges"))
				nMode = MODE_EDGES	
			endif
			
			if(stringmatch(s_value, "RunAvg"))
				nMode = MODE_RUNAVG	
			endif
			
			break
			
		case "SWaveArithm_APlusB" :
			nOperation = ARITHM_PLUSB
			sParam = XPSFit_GetCsrWave("B") + ";" + XWaveName("",XPSFit_GetCsrWave("B")) 
			sWaveList = RemoveFromList(sParam,sWaveList)
			
			for(idx = 0; idx < itemsinlist(sWaveList); idx += 1)
				sParam += ";" + XWaveName("",StringFromList(idx,sWaveList)) 
			endfor
			
			break
			
		case "SWaveArithm_AMinusB" :
			nOperation = ARITHM_MINUSB
			sParam = XPSFit_GetCsrWave("B")+  ";" + XWaveName("",XPSFit_GetCsrWave("B")) 
			sWaveList = RemoveFromList(sParam,sWaveList)
			
			for(idx = 0; idx < itemsinlist(sWaveList); idx += 1)
				sParam += ";" + XWaveName("",StringFromList(idx,sWaveList)) 
			endfor
			
			break	
		
		case "SWaveArithm_ADivB" :
			nOperation = ARITHM_DIVB
			sParam = XPSFit_GetCsrWave("B")+ ";" + XWaveName("",XPSFit_GetCsrWave("B")) 
			sWaveList = RemoveFromList(sParam,sWaveList)
			
			for(idx = 0; idx < itemsinlist(sWaveList); idx += 1)
				sParam += ";" + XWaveName("",StringFromList(idx,sWaveList)) 
			endfor
			
			break
		
		case "SWaveArithm_AMultB" :
			nOperation = ARITHM_MULTB
			sParam = XPSFit_GetCsrWave("B")+ ";" + XWaveName("",XPSFit_GetCsrWave("B")) 
			sWaveList = RemoveFromList(sParam,sWaveList)
			
			for(idx = 0; idx < itemsinlist(sWaveList); idx += 1)
				sParam += ";" + XWaveName("",StringFromList(idx,sWaveList)) 
			endfor
			
			break
		
		case "SWaveArithm_APlusC" :
			nOperation = ARITHM_PLUSC
			sParam = num2str(nC)
			break
			
		case "SWaveArithm_AMinusC" :
			nOperation = ARITHM_MINUSC
			sParam = num2str(nC)
			break	
		
		case "SWaveArithm_ADivC" :
			nOperation = ARITHM_DIVC
			sParam = num2str(nC)
			break
		
		case "SWaveArithm_AMultC" :
			nOperation = ARITHM_MULTC
			sParam = num2str(nC)
			break
		
		case "SWaveArithm_APlusC" :
			nOperation = ARITHM_PLUSC
			sParam = num2str(nC)
			break
		
		case "SWaveArithm_AToLeft" :
			nOperation = ARITHM_BEPLUS
			sParam = num2str(nBEShift)
			break	
		
		case "SWaveArithm_AToRight" :
			nOperation = ARITHM_BEMINUS
			sParam = num2str(nBEShift)
			break
			
		case "SWaveArithm_AToBShift":
			nOperation = ARITHM_BEPLUS
			 XPSFit_GetCsrWave("A")
			 XPSFit_GetCsrWave("B")
			sParam = num2str(xcsr(B) - xcsr(A))
			break
	endswitch

	
	
	if (nOperation == ARITHM_AVERAGE)
		sWaveList = XPSFit_RemoveSWaves(sWaveList,0,"_avg")
	endif
	
	if (nOperation == ARITHM_SUM)
		sWaveList = XPSFit_RemoveSWaves(sWaveList,0,"_sum")
	endif
	
	// Save history
	string sSaveWaveList = ""
	for(idx = 0; idx < itemsinlist(sWaveList); idx += 1)
		sSaveWaveList += GetDataFolder(1) + StringFromList(idx, sWaveList) + ";"
	endfor

	switch (nOperation)
		case ARITHM_NORMAREAS:
			XPSFit_SaveToHistory(1,StringFromList(0,sSaveWaveList),WinName(0,1),nOperation,num2str(Area($StringFromList(0,sWaveList))), num2str(nMode))
			for(idx = 1; idx < itemsInList(sWaveList); idx += 1)
				XPSFit_SaveToHistory(0,StringFromList(idx,sSaveWaveList),WinName(0,1),nOperation,num2str(Area($StringFromList(idx,sWaveList))), num2str(nMode))
			endfor
			break
		default:
			XPSFit_SaveToHistory(1,sSaveWaveList,WinName(0,1),nOperation,sParam, num2str(nMode))
			break
		
	endswitch
	
	// Do the arithmetic
	string sResWaveList =  XPSFit_WaveArithm(sWaveList, nOperation,sParam,nMode)

	// Display / append results
	XPSFit_DisplayResults(sResWaveList)
		
	SetDataFOlder sCurFolder
end
//..............................................................................................................................
function /S XPSFit_WaveArithm(sWaveList, nOperation, sParam, nMode)
	string	sWaveList
	variable	nOperation
	string	sParam
	variable	 nMode
	
	//variable	nC,nBEShift, nbin
	
	if(nOperation == ARITHM_PLUSB || nOperation == ARITHM_MINUSB || nOperation == ARITHM_DIVB || nOperation == ARITHM_MULTB)
		wave /Z wB = $StringFromList(0,sParam)
		wave /Z wXB = $StringFromList(1,sParam)
	else
		variable nParam = str2num(sParam)
	endif
	
	if (!strlen(sWaveList))
		return ""
	endif
	
	sWaveList = sortlist(sWaveList,";",16)							
	wave	 	w2DWave = $StringFromList(0,sWaveList)					// 2D wave
	variable	nDimSize = DimSize(w2DWave,1)		
	variable	nNumWaves = nDimSize? nDimSize : ItemsInlist(sWaveList)
	string	sResWaveList = ""
	variable	idx,idi
	variable	nDir = 1
	
	switch (nOperation)
		case ARITHM_AVERAGE:
		case ARITHM_SUM:
			if (nDimSize)
				wave wRes = XPSFit_WaveArithmSum (NameOfWave(w2DWave),nOperation)
			else
				wave wRes = XPSFit_WaveArithmSum (sWaveList, nOperation)
			endif			
			sResWaveList = NameOfWave(wRes) + ";"
			break
		
		case ARITHM_BINHOR:
			if (nDimSize)
				sResWaveList = XPSFit_WaveArithmBinHor (NameOfWave(w2DWave),nParam, nMode)
			else
				sResWaveList = XPSFit_WaveArithmBinHor (sWaveList,nParam, nMode)
			endif			
			break
		case ARITHM_BINVER:
			if(nDimSize)
				sResWaveList = XPSFit_WaveArithmBinVer(w2DWave,nParam, nMode)
			endif
			break
			
		case ARITHM_BEMINUS:
			nDir = -1
		case ARITHM_BEPLUS:
			if(nDimSize)
				//print leftx(w2DWave) + nDir * nParam, rightx(w2DWave) + nDir * nParam - deltax(w2DWave)
				//abort
				SetScale /I x, leftx(w2DWave) + nDir * nParam, rightx(w2DWave) + nDir * nParam - deltax(w2DWave), w2DWave
				
			else
				string s = XWaveName("",NameOfWave(w))
						
				for(idx = 0; idx < nNUmWaves; idx += 1)
					wave	w = $stringFromList(idx, sWaveList)
					if(strlen(s))
						wave wXWave = $s
						wXWave = wXWave + nDir * nParam	
					else
						SetScale /I x, leftx(w) + nDir * nParam, rightx(w) + nDir * nParam - deltax(w), w
					endif
				endfor
			endif
			
			break
		
		default :
			for(idx = 0; idx < nNumWaves; idx += 1)
				if (nDimSize)	
					wave	w = XPSFit_GetWaveFromMatrix(w2DWave,idx)	// if 2D wave - get trace from matrix
				else
					wave	w = $stringFromList(idx, sWaveList)		// if list of 1D waves - get idx wave from list
					wave /Z wX = $stringFromList(idx + 2, sParam)
				endif
				
				switch (nOperation)
					case ARITHM_NORMAREAS:
						WaveTransform /O normalizeArea w
						break
					
					case ARITHM_PLUSB:
						
						if(WaveExists(wX))
							for(idi = 0; idi < numpnts(w); idi += 1)
								w[idi] += interp(wX[idi],wXB,wB)
							endfor
						else
							w = w(x) + wB(x)
						endif
						
						break
					
					case ARITHM_MINUSB:
						
						if(WaveExists(wX))
							for(idi = 0; idi < numpnts(w); idi += 1)
								w[idi] -= interp(wX[idi],wXB,wB)
							endfor
						else
							w = w(x) - wB(x)
						endif
						break
					
					case ARITHM_DIVB:
						
						if(WaveExists(wX))
							for(idi = 0; idi < numpnts(w); idi += 1)
								w[idi] /= interp(wX[idi],wXB,wB)
							endfor
						else
							w = w(x) / wB(x)
						endif
						
						break
					
					case ARITHM_MULTB:
						
						if(WaveExists(wX))
							for(idi = 0; idi < numpnts(w); idi += 1)
								w[idi] *= interp(wX[idi],wXB,wB)
							endfor
						else
							w = w(x) * wB(x)
						endif
						
						break
					
					case ARITHM_PLUSC:
						w = w(x) + nParam
						break
					
					case ARITHM_MINUSC:
						w = w(x) - nParam
						break
					
					case ARITHM_DIVC:
						w = w(x) / nParam
						break
					
					case ARITHM_MULTC:
						w = w(x) * nParam
						break
										
				endswitch
					
				if(nDimSize)
					w2DWave[][idx] = w[p]
				endif
				
			endfor
			break
	
	
	endswitch
	
	return sResWaveList
end	
//..............................................................................................................................

function /S XPSFit_WaveArithmBinHor(sWaveList, nBin, nMode)
	string	sWaveList
	variable	nBin, nMode
	
	wave	 	w2DWave = $StringFromList(0,sWaveList)					// 2D wave
	variable	nDimSize = DimSize(w2DWave,1)		
	variable	nNumWaves = nDimSize? nDimSize : ItemsInlist(sWaveList)
	string	sResList = ""
	variable 	idx,idy,i
	variable	nY, nJump
	variable	nYDimSize = DimSize(w2DWave,0)
	string	sExt = "_bH" + num2str(nBin)
		
	if(nMode == MODE_EDGES) // edges
		nJump = nBin
	endif
	
	if (nMode == MODE_RUNAVG) // running average
		nJump = 1
	endif
	
	if (nDimSize) // if matrix
		duplicate /O w2DWave $(NameOfWave(w2DWave) + sExt)
		wave wRes2DWave = $(NameOfWave(w2DWave) + sExt)
		Redimension /N=(ceil(nYDimSize/nJump),-1) wRes2DWave
		//print leftx(w2DWave) + (deltax(w2DWave)*(nBin-1)/2), rightx(w2DWave) - deltax(w2DWave)+(deltax(w2DWave)*(nBin-1)/2)
		
		if(nJump == 1)
			SetScale /I x, leftx(w2DWave) + (deltax(w2DWave)*(nBin-1)/2), rightx(w2DWave) - deltax(w2DWave)+(deltax(w2DWave)*(nBin-1)/2), wRes2DWave
		else
			SetScale /I x, leftx(w2DWave) , rightx(w2DWave) - deltax(w2DWave), wRes2DWave
		endif
		
		for(idx = 0; idx < nDimSize; idx += 1)
			for(idy = 0; idy < nYDimSize; idy += nJump)
				nY = 0
				
				for(i = idy; i < idy + nBin; i += 1)
					nY += w2DWave[i][idx]	
				endfor
				
				wRes2DWave[idy/nJump][idx] = nY / nBin
			endfor
		endfor
		
		sResList = NameOfWave(wRes2DWave)
	else // if list of 1D waves
		for(idx = 0; idx < nNumWaves; idx += 1)
			wave w = $(StringFromList(idx,sWaveList))
			Duplicate /O w $(NameOfWave(w) + sExt)
			wave wRes = $(NameOfWave(w) + sExt)
			Redimension /N=(ceil(numpnts(w)/nJump)) wRes
			if(nJump == 1)
				SetScale /I x, leftx(w2DWave) + (deltax(w2DWave)*(nBin-1)/2), rightx(w2DWave) - deltax(w2DWave)+(deltax(w2DWave)*(nBin-1)/2), wRes
			else
				SetScale /I x, leftx(w2DWave) , rightx(w2DWave) - deltax(w2DWave), wRes
			endif
			
			for (idy = 0; idy < numpnts(w); idy += nJump)
				nY = 0
			
				for(i = idy; i < idy + nBin; i += 1)
					nY += w[i]
				endfor
			
				wRes[idy/nJump] = nY/nBin
			endfor
			sResList += NameOfWave(wRes) + ";"
		endfor
	endif	

	return sResList
end
//........................................................................................................................
function /s XPSFit_WaveArithmBinVer(w2DWave,nBin, nMode)
	wave 		w2DWave
	variable	nBin, nMode
	
	variable nJump
	
	if(nMode == MODE_EDGES) // edges
		nJump = nBin
	endif
	
	if (nMode == MODE_RUNAVG) // running average
		nJump = 1
	endif
	
	Duplicate /O w2DWave $(NameOfWave(w2DWave) + ("_bV" + num2str(nBin)))
	wave wRes = $(NameOfWave(w2DWave) + ("_bV" + num2str(nBin)))
	Redimension /N=(-1,ceil(DimSize(w2DWave,1)/nJump)) wRes
	variable	idx, idy,i, nY
	
	for(idy = 0; idy < dimSize(w2DWave,0); idy += 1)
		for(idx = 0; idx < DimSize(w2DWave,1); idx += nJump)
			nY = 0
			for (i = idx; i < idx + nBin; i += 1)
				nY += w2DWave[idy][i]
			endfor
			wRes[idy][idx/nJump] = nY / nBin
		endfor
	endfor
	 
	
	return NameOfWave(wRes) + ";"
end

//...............................................................................................................................
	
function /WAVE XPSFit_WaveArithmSum(sWaveList, nOperation)
	string 	sWaveList
	variable	nOperation
	
	wave	 	w2DWave = $StringFromList(0,sWaveList)					// 2D wave
	variable	nDimSize = DimSize(w2DWave,1)		
	variable	nNumWaves = nDimSize? nDimSize : ItemsInlist(sWaveList)
	variable	idx
	
	if(!nDimSize && nNumWaves == 1)
		return $StringFromList(0,sWaveList)
	endif
	
	for(idx = 0; idx < nNumWaves; idx += 1)
		if (nDimSize)	
			wave	w = XPSFit_GetWaveFromMatrix(w2DWave,idx)	// if 2D wave - get trace from matrix
		else
			wave	w = $stringFromList(idx, sWaveList)		// if list of 1D waves - get idx wave from list
		endif
		
		if(idx == 0)
			switch (nOperation)
				case ARITHM_AVERAGE:
						
						if(nDimSize)
							duplicate /O w $(NameOfWave(w2DWave) + "_avg")
							wave wRes = $(NameOfWave(w2DWave) + "_avg")
						else
							Duplicate /O w $(NameOfWave(w) + "_avg")
							wave wRes = $(NameOfWave(w) + "_avg")	
						endif
										
						wRes = 0
						break
					
					case ARITHM_SUM:
						if(nDimSIze)
							duplicate /O w $(NameOfWave(w2DWave) + "_sum")
							wave wRes = $(NameOfWave(w2DWave) + "_sum")
						else
							Duplicate /O w $(NameOfWave(w) + "_sum")
							wave wRes = $(NameOfWave(w) + "_sum")
						endif
						
						wRes = 0
						break
			endswitch
		endif 
		
		wRes = wRes(x) + w(x)
		
	endfor
	
	if(nOperation == ARITHM_AVERAGE)
		wRes /= nNumWaves
	endif
	
	KillWaves /Z wTempWave
	
	return wRes
	
end
	
//==============================================================================================================================	

	
	
	
//	string sCurDataFolder = GotoDataFOlder()//
//	
//	variable nDisplayRes = bDisplayWArithmRes
//	variable nAppendRes = bAppendWArithmRes
	
	
//	if (!strlen(sWaveList))
//		sWaveList =WaveLIst("*",";","WIN:")		
//	else
//		nDisplayRes = 0
//		nAppendRes = 0
//	endif
	
//	sWaveList = sortlist(sWaveList,";",16)
//	variable nDim, nNumWaves
	
//	if(DimSize($StringFromList(0,sWaveList),1))
//		nDim = 1 //2D wave
//		wave w2DWave = $StringFromList(0,sWaveList)
//		nNumWaves = DimSize(w2DWave,1)
//	else
//		nDim = 0 // 1D wave
//		nNumWaves = ItemsInList(sWaveList)
//	endif
	
	//variable nAY
//	variable nE
	
//	wave /Z w = csrwaveref(A)
//	if (WaveExists(w))
//		nE = xcsr(A)
//	else
//		nE=  inf
//	endif
	
//	variable bBack
//	controlinfo pmBackWave
	
//	if(!stringmatch(s_value, "no bkgnd wave"))
//		bBack = 1
//		wave wBack = $s_value	
//	else
//		bBack = 0
//	endif
	
//	variable bDiv = 0
//	string sExt = "_sum"
//	variable idx, nlx, nrx, nt
	
//	strswitch (sCtrlName)
//		case "AverWaves":
//			bDiv = 1
//			sExt = "_avg"
//		case "SumWaves":
//			switch (nDim)
//				case 0:
//					duplicate /O $(StringFromList(0,sWaveList)) $(StringFromList(0,sWaveList) + sExt)
//					wave wSum = $(StringFromList(0,sWaveList) + sExt)
//					break
//				case 1:
//					wave w = XPSFit_GetWaveFromMatrix($(StringFromList(0,sWaveList)),0)
//					duplicate /O wTempWave $(StringFromList(0,sWaveList) + sExt)
//					wave wSum = $(StringFromList(0,sWaveList) + sExt)
//					break				
//			endswitch
			
//			for (idx = 1; idx <nNumWaves; idx += 1)
//				if(nDim)
//					wave wW = XPSFit_GetWaveFromMatrix(w2DWave,idx)
//				else
//					wave wW = $stringFromList(idx,sWaveList)
//				endif
//				wSum = wSum(x) + wW(x)
//			endfor
			
//			if (bDiv)
//				wSum /=nNumWaves
//			endif	
			
//			if (nAppendRes && !nDim)
//				AppendToGraph wSum 
//			endif
			
//			if (nDisplayRes)
//				Display
//				AppendToGraph wSum
//			endif	
//						
//			break

///		case "WaveArithm_Norm":
			
	//		for (idx = 0; idx < nNumWaves; idx += 1)
//				if (nDim)
//					wave w = XPSFit_GetWaveFromMatrix(w2DWave,idx)
//				else
//					wave w = $stringfromlist(idx,sWaveList)
//				endif
				
//				if (bBack)
//					w = w(x) / wBack(x)
//				else
//					nlx = leftx(w)
//					nrx = rightx(w) - deltax(w)
//					nt = nlx
//					
//					if(nlx > nrx)
//						nlx = nrx
//						nrx = nt
//					endif
			
//					nE = nE == inf ?  min(nlx,nrx) : nE
//					WaveStats /Q /R = (nE - 0.5, nE + 0.5) w
//					w /= v_avg
//				endif
//				
//				if(nDim)
//					w2DWave[][idx] = w[p]
//				endif
//			endfor
//			break
		
//		case "WaveArithm_Back":
//			for (idx = 0; idx < nNumWaves; idx += 1)
//				if (nDim)
//					wave w = XPSFit_GetWaveFromMatrix(w2DWave,idx)
//				else
//					wave w = $stringfromlist(idx,sWaveList)
//				endif
				
//				if (bBack)
//					w = w(x) - wBack(x)
//				else
//					nlx = leftx(w)
//					nrx = rightx(w) - deltax(w)
//					nt = nlx
//					
//					if(nlx > nrx)
//						nlx = nrx
//						nrx = nt
//					endif
			
//					nE = nE == inf ?  min(nlx,nrx) : nE
//					WaveStats /Q /R = (nE - 0.5, nE + 0.5) w
//					w -= v_avg
//				endif
				
//				if(nDim)
//					w2DWave[][idx] = w[p]
//				endif
//			endfor
//			break
		
//		case "NormAreaWaves":
//			for (idx = 0; idx < nNumWaves; idx += 1)
//				if (nDim)
//					wave w = XPSFit_GetWaveFromMatrix(w2DWave,idx)
//				else
//					wave w = $stringfromlist(idx,sWaveList)
//				endif
				
//				wavetransform /O normalizeArea w
				
//				if(nDim)
//					w2DWave[][idx] = w[p]
//				endif
//			endfor
//			break
	
//	endswitch

//	setdatafolder sCurDataFolder
//end

function XPSFit_GetAverageY(w,nE,nDE)
	wave w
	variable nE, nDE
	
	variable nRightP = x2pnt(w,nE-nDe/2)
	variable nLeftP = x2pnt(w,nE+nDe/2)
	
	variable nTemp
	
	if (nLeftP > nRightP)
		nTemp = nLeftP
		nLeftP = nRightP
		nRightP = nLeftP
	endif
	
	variable nAE
	variable idx
	
	for (idx = nLeftP; idx <= nRightP; idx += 1)
		nAE += w[idx]
	endfor
	
	nAE /= nRightp - nLeftp + 1
	
	return nAE
end

function /Wave XPSFit_GetWaveFromMatrix(wMatrix,ncol)
	wave wMatrix
	variable ncol
	
	make /O/N=(DimSize(wMatrix,0)) wTempWave
	SetScale /I x DimOffset(wMatrix,0), DimOffset(wMatrix,0) + DimSize(wMatrix,0) * DimDelta(wMatrix,0), wTempWave
	variable idx
	
	for(idx = 0; idx < DimSize(wMatrix,0); idx += 1)
		wTempWave[idx] =  wMatrix[idx][nCol]
	endfor

	return wTempWave
end

function XPSFit_SetWaveInMatrix(wMatrix, wWave, nCol)
	wave wMatrix, wWave
	variable nCol
	
	variable idx
	
	for(idx = 0; idx < DimSize(wMatrix,0); idx += 1)
		wMatrix[idx][nCol] = wWave[idx]	
	endfor
end





//function XPSFit_SWaveArithmfunk (sCtrlName)
//	String sCtrlName
//	/
//	Wave /Z wCsrA = CsrWaveRef (A)
//	if (!WaveExists(wCsrA))
//		Abort "No cursor A on any waves"
//	endif
//	ControlInfo $("WaveArithm_XShift")
//	Variable nXShift = v_value
//	ControlInfo $("WaveArithm_C")
//	Variable nC = v_value
//	Variable nLeftX = 0
//	Variable nRightX = 0
//	Variable nAverE
	
//	strswitch (sCtrlName)
//		case "WaveArithm_APlusB":
//			Wave wCsrB = CheckBOnGraph()
//			XPSFit_WaveArithm_APlusB(wCsrA, wCsrB,1)
//			//wCsrA = wCsrA(x) + wCsrB(x)abort
//			break
//		
//		case "WaveArithm_AMinusB":
//			Wave wCsrB = CheckBOnGraph()
//			XPSFit_WaveArithm_APlusB(wCsrA, wCsrB,2)
//			break
	
//		case "WaveArithm_ADivB":
//			Wave wCsrB = CheckBOnGraph()
//			XPSFit_WaveArithm_APlusB(wCsrA, wCsrB,4)
//			break
	
//		case "WaveArithm_AMultB":
//			Wave wCsrB = CheckBOnGraph()
//			XPSFit_WaveArithm_APlusB(wCsrA, wCsrB,3)
//			break
			
//		case "WaveArithm_sum":
			
//			break
			
//		case "WaveArithm_APlusC":
//			wCsrA = wCsrA(x) + nC
//			break
		
//		case "WaveArithm_AMinusC":
//			wCsrA = wCsrA(x) - nC
//			break
		
//		case "WaveArithm_AMultC":
//			if (nC == 0)
//				DoAlert 1, "Multiplication by zero. You will lose all data. Continue?"
//				if (v_flag == 2)
///					abort
	//			endif
//			endif
			
//			wCsrA = wCsrA(x) * nC
//			break
		
//		case "WaveArithm_ADivC":
//			if (nC == 0)
//				Abort "Division by zero. Not good."				
//			endif
//			wCsrA = wCsrA(x) / nC
//			break
//		case "WaveArithm_AToLeft":
//			string sXWName = stringbykey("XWAVE",traceinfo("",Stringfromlist(0,TraceNameList("",";",0)),0))
//			if (strlen(sXWName))
//				wave wXWName = $sXWName
//				wXWName += nXShift
//			else
//				nLeftX = LeftX(wCsrA)
//				nRightX = pnt2X(wCsrA,numpnts(wCsrA) - 1)
//				SetScale /I x ,nLeftX + nXShift, nRightX + nXShift, wCsrA
//			endif
//			break
//		case "WaveArithm_AToRight":
//			 sXWName = stringbykey("XWAVE",traceinfo("",Stringfromlist(0,TraceNameList("",";",0)),0))
//			if (strlen(sXWName))
//				wave wXWName = $sXWName
//				wXWName -= nXShift
//			else
//				nLeftX = LeftX(wCsrA)
//				nRightX = pnt2X(wCsrA,numpnts(wCsrA) - 1)
//				SetScale /I x ,nLeftX - nXShift, nRightX - nXShift, wCsrA
//			endif
//			break
//		case "WaveArithm_Norm":
///			nAverE = XPSGetAverageE (wCsrA)
	//		wCsrA = wCsrA / nAverE  
//			break
//		case "WaveArithm_Back":
//			nAverE = XPSGetAverageE (wCsrA)
//			wCsrA = wCsrA - nAverE 
//			break
//	endswitch	

//end

function /WAVE CheckBOnGraph()
	Wave wCsrB = CsrWaveRef (B)
	if (!WaveExists(wCsrB))
		Abort "No cursor B on any waves"
	endif
	return wCsrB
end

function XPSGetAverageE (wWave)
	Wave wWave
	
	Variable nCurE = xcsr(A)
	Variable nAver = 0
	Variable i = 0
	Variable t = 0
	
	for (i = nCurE - 0.5; i < nCurE + 0.5; i += 0.05)
		nAver += wWave(i)
		t += 1
	endfor
	
	nAver /= t
	return nAver	
end

//__________________________________________________
function/ WAVE XPSFit_WaveArithm_APlusB (wYA, wYB, nOp) // nOp: 1 - plus, 2 - minus, 3 - times; 4 - divide
	wave wYA, wYB
	variable nOp
	
	variable idx
	
	wave /Z wXA = $XWaveName("",NameOfWave(wYA))
	wave /Z wXB =$ XWaveName("",NameOfWave(wYB))
	wave /Z wRes = wYA
	
	if (!WaveExists(wXA) && !WaveExists(wXB))
		switch (nOp)
			case 1:
				wres = wYA(x) + wYB(x)
				break
			
			case 2:
				wres = wYA(x) - wYB(x)
				break
			
			case 3:
				wres = wYA(x) * wYB(x)
				break
			
			case 4: 
				wres = wYA(x) / wYB(x)
				break
			endswitch
		return wres
	endif
	
	
	
	variable nLowEA 
	variable nHighEA
	
	if (wXA[0] < wXA[Dimsize(wXA,0) - 1])
		nLowEA = wXA[0]
		nHighEA = wXA[Dimsize(wXA,0) - 1]
	else
		nLowEA = wXA[Dimsize(wXA,0) - 1]
		nHighEA =  wXA[0]
	endif
	
	variable nLowEB 
	variable nHighEB
	
	if (wXB[0] < wXB[Dimsize(wXB,0) - 1])
		nLowEB = wXB[0]
		nHighEB = wXB[Dimsize(wXB,0) - 1]
	else
		nLowEB = wXB[Dimsize(wXB,0) - 1]
		nHighEB =  wXB[0]
	endif
	
	variable nL, nR
	
	if (nHighEA < nLowEB || nLowEA > nHighEB)
		return wRes
	endif
	
	
	nL = nLowEA > nLowEB ? nLowEA : nLowEB	
	nR = nHighEA < nHighEB ? nHighEA : nHIghEB
	
	variable nNumPts 
 	wave wX = wXA
	
	//if (y2p(wXA,nr) - y2p(wXA,nL) > y2p(wXB,nr) - y2p(wXB,nL)  )
	//	nNumPts = y2p(wXB,nr) - y2p(wXB,nL) + 2
	//	wave wX = wXB
	//else
	//	nNumPts = y2p(wXA,nr) - y2p(wXA,nL) + 2
	//	wave wX = wXA
	//endif
	nNumPts = numpnts(wYA)
	
	make /O/N = (numpnts(wYA)) $(NameOfWave(wYA) + "N")
	wave wTmp = $(NameOfWave(wYA) + "N")
	make /O/N = (numpnts(wYA)) $(NameOfWave(wXA) + "N")
	wave wETemp =  $(NameOfWave(wXA) + "N")
	
	
	variable nStartP = y2p(wX,nL)
	variable nE

	
	for (idx = 0; idx <  nNumPts; idx += 1)
		nE = wX[nStartP + idx]
		//print nE, idx, interp(nE,wXA, wYA) ,  interp(nE,wXB,wYB)
		wETemp[idx] = nE
		switch (nOp)
			case 1:
				wTmp[idx] = interp(nE,wXA, wYA) +  interp(nE,wXB,wYB)
				break	
				
			case 2: 
				wTmp[idx] = interp(nE,wXA, wYA) -  interp(nE,wXB,wYB)
				break
			
			case 3: 
				wTmp[idx] = interp(nE,wXA, wYA) *  interp(nE,wXB,wYB)
				break
				
			case 4:
				wTmp[idx] = interp(nE,wXA, wYA) /  interp(nE,wXB,wYB)
				break
				
		endswitch
		
	endfor
	AppendToGraph wTmp vs wETemp
	//Redimension /N = (nNumPts)
	
end

//_______________________________________________________________
//function XPSFit_GetY (wYWave, wXWave, nX)
//	wave wYWave, wXWave
//	variable nX
//	
//	variable idx, t, nP
//	
//	//print wXWave[0], wXWave[DimSize(wXWave,0) - 1]
//	if (nX >= wXWave[0] && nX <= wXWave[DimSize(wXWave,0) - 1])
//		t = 1
//		idx = 0
//	elseif(nX <= wXWave[0] && nX >= wXWave[DimSize(wXWave,0) - 1])
//		idx = 0
//		t = 1/


//		else//

//		if (nX <= wXWave[0] && nX >= wXWave[DimSize(wXWave,0) - 1])
//			idx = DimSize(wXWave,0) -1
//			t = -1
//		endif
//	endif
	
	//print idx
	
//	do
//		idx += t
//		if(idx > numpnts(wXWave))
//			return wYWave[idx]
//		endif
//	while (nX >= wXWave[idx]) // always returns either point exactly or highest point in case of mismatch
//	 
//	variable nXp = idx -t + (nX - wXWave[idx - t]) / (wXWave[idx] - wXWave[idx - t])
//	
//	return wYWave[nXp]	
//end

function y2p(w,y)
	wave w
	variable y
	
	variable idx, t
	
	if (w[0] < w[numpnts(w) - 1])
		t = 1
		if (y > w[numpnts(w) - 1])
			return w[numpnts(w) - 1]
		endif
		if (y < w[0])
			return w[0]
		endif
	else
		t= -1
		if (y < w[numpnts(w) - 1])
			return w[numpnts(w) - 1]
		endif
		if (y > w[0])
			return w[0]
		endif
	endif
	
	
	do
		idx += 1
	while (y > w[idx])
	
	return idx -1

end
//_________________________________________________________________

// Set colors of the waves from the top graph in ranbow distrib. 
//  Written by Georg Held

function XPS_SetRainbowColours(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr 
	
	string sWaveList = WaveList("*",";","WIN:")

	if(DimSize($stringfromlist(0,sWaveList),1))
		string s = stringfromlist(0,sWaveList)
		strswitch(popStr)
			case "Rainbow":
				ModifyImage $s, ctab={*,*,Rainbow,0}
				break
	
			case "Inversed Rainbow":
				ModifyImage $s ctab={*,*,Rainbow,1}
				break
		endswitch
	else
		
		String wave_list =TraceNameList("",";",1)
	
		if (stringmatch (popStr, "Rainbow") || stringmatch (popStr, "RBBGY"))
			wave_list = SortList (wave_list, ";",16)
		endif
		if (stringmatch (popStr, "Inversed Rainbow"))
			wave_list = SortList (wave_list, ";",17)
		endif
		
		Variable num_end = ItemsInList(wave_list) - 1	
		Variable num_now
		variable nD
		String wave_name	
		make /O/N=3 ColourWave
		
		do
			wave_name = StringFromList(num_now, wave_list)
			strswitch (popStr)
				case "Rainbow":
				case "INversed Rainbow":
					Wave wColourWave = GH_GetColor(num_now, 0, num_end)
					break
				case "RBBGY":
					Wave wColourWave = XPSFit_ColorWave_RBBGY(ColourWave,num_now)
					break
				
			endswitch
			
			ModifyGraph rgb($wave_name)=(wColourWave[0],wColourWave[1], wColourWave[2])		
			num_now += 1	
		while (num_now <= num_end)
	
	endif
end


function /wave XPSFit_ColorWave_RBBGY(wColorWave,nNum)
	wave wColorWave
	variable nNum
	
	switch (nNum)
		case 0: // red
			wColorWave[0] = 65535
			wColorWave[1] = 0
			wColorWave[2] = 0
			break
			
		case 1: // black
			wColorWave[0] = 0
			wColorWave[1] = 0
			wColorWave[2] = 0
			break
		case 2: // blue
			wColorWave[0] = 0
			wColorWave[1] = 0
			wColorWave[2] = 65535
			break
		case 3: // green
			wColorWave[0] = 0
			wColorWave[1] = 34952
			wColorWave[2] = 0
			break
		case 4: // orange
			wColorWave[0] = 65535
			wColorWave[1] = 43690
			wColorWave[2] = 0
			break
		case 5: // pink 
			wColorWave[0] = 65535
			wColorWave[1] = 16385
			wColorWave[2] = 55749
			break
		case 6: // grey 
			wColorWave[0] = 34952
			wColorWave[1] = 34952
			wColorWave[2] = 34952
			break
		case 7: // sky blue 
			wColorWave[0] = 0
			wColorWave[1] = 65535
			wColorWave[2] = 65535
			break
		case 8: // salad 
			wColorWave[0] = 0
			wColorWave[1] = 65535
			wColorWave[2] = 0
			break
		case 9: // Yellow 
			wColorWave[0] = 65535
			wColorWave[1] = 65535
			wColorWave[2] = 0
			break
			
			
	endswitch
	return wColorWave
end


Function/WAVE GH_GetColor(num_now, num_start, num_end)
variable num_now, num_start, num_end

variable num_del, num_del_now
variable red, blue, green
wave colors = $("ColourWave")

num_del = num_end - num_start
num_del_now = num_now - num_start

if (num_del == 0)
	red = 65535
	green = 0
	blue = 0
else
// Rainbow colours: red - yellow - green - cyan - blue
	if(num_del_now  < 0.25*num_del)
		red = 65535
		green =   min(65535 * 4 * (num_del_now  / num_del), 65535)
		blue = 0
	else
		if (num_del_now < 0.50*num_del)
			red =   max( 65535 * (2 - 4*(num_del_now  / num_del) ), 0)
			green = 65535
			blue = 0
		else
			if (num_del_now < 0.75*num_del)
				red = 0
				green = 65535
				blue =   max(65535 * (-2 + 4*(num_del_now  / num_del) ), 0)
			else
				if (num_del_now < num_del)		
					red = 0
					green =   max( 65535 * (4  - 4*(num_del_now  / num_del) ), 0)
					blue = 65535
				else
					red = 0
					green = 0
					blue = 65535
				endif
			endif
		endif
	endif
endif
		
colors[0] = round(red)
colors[1] = round(green)
colors[2] = round(blue)
return colors
End
//________________________________________________________________________________________

// does vertical (non-dispersive) binning 

//function WaveDoBinYProc (ctrlName) 
	String ctrlName

	Variable i = 0, j = 0, k = 0, l = 0
	String sDataFolder, sWaveBaseName
	Variable nBin = 0;
		
	String sImgWaveName = ImageNameList("",";") // get image name on the graph
	if (strlen (sImgWaveName) == 0)
		return 0
	endif
	sImgWaveName = sImgWaveName[0,strlen(sImgWaveName)-2] // cut ; sign
	Wave wCurMatrixWave = ImageNameToWaveRef("",sImgWaveName);
	sDataFolder = GetWavesDataFolder (wCurMatrixWave,1)
	String sCurDF = GetDataFolder(1)
	SetDataFolder $sDataFolder
	sWaveBaseName = sImgWaveName[0,strlen(sImgWaveName) - 3]	
	String suf = ""
	if (cmpstr(sWaveBaseName[strlen(sWaveBaseName) -1] , "_") != 0)
		sWaveBaseName =  (NameOfWave(wCurMatrixWave))[0,strlen(NameOfWave(wCurMatrixWave)) - 10]
		suf = "_wobgr"
	endif
	ControlInfo $("WaveBin1D")
	nBin =  str2num(s_value)
	make /O /N = (DimSize(wCurMatrixWave,0)) $("tempwave")
	Wave wTempWave = $("tempwave")
	make /O /N = (DimSize(wCurMatrixWave, 0) , DimSize(wCurMatrixWave, 1) / nBin) $(sImgWaveName + "bV" + num2str(nBin))
	setScale x,  DimOffset(wCurMatrixWave,0), DimSize (wCurMatrixWave,0) * DimDelta (wCurMatrixWave,0) +  DimOffset(wCurMatrixWave,0), $(sImgWaveName + "bV" + num2str(nBin)) // rescale copy wave
		
	Wave wBinWave = $(sImgWaveName + "bV" + num2str(nBin))
	
	for (j = 0; j < DimSize(wCurMatrixWave,1); j += nBin)		
		for (k = j; k < j +  nBin; k += 1)
	
			for (i = 0; i < DimSize(wCurMatrixWave,0); i += 1) 
				wTempWave[i] += wCurMatrixWave [i][k]
			endfor
				
			l+=1
		endfor		
		wTempWave /= l	
		for (i = 0; i < DimSize(wCurMatrixWave,0); i += 1) // then copy copy wave into new matrix
			wBinWave [i][j/nBin] = wTempWave[i]
		endfor
		l = 0	
		wTempWave = 0			
	endfor

	Display; AppendImage $(sImgWaveName + "bV" + num2str(nBin))
	SetDataFolder $sCurDF
end
//____________________________________________________

// gets current data folder and then goes to the folder with top graph wave
function /S GotoDataFolder()

	String sCurDataFolder = GetDataFolder(1)
	String sWaveName = StringFromList(0,ImageNameList("",";")) // get image name on the graph
	//print sWaveName
	String sWaveDataFolder = "root:"
	if (strlen (sWaveName) == 0)
		sWaveName = StringFromList(0,TraceNameList("",";",1))
		if (strlen(WinName(0,1)))
			Wave/Z wCurWave = WaveRefIndexed("",0,1)
			if (WaveExists(wCurWave))
				sWaveDataFolder = GetWavesDataFolder(wCurWave,1)
			endif
		endif
	else
		Wave/Z wCurWave = ImageNameToWaveRef("", StringFromList(0,ImageNameList("",";")))
		if (WaveExists(wCurWave))
			sWaveDataFolder = GetWavesDataFolder(wCurWave,1)
		endif
	endif		
	SetDataFOlder(sWaveDataFolder)	
	return sCurDataFolder
end
 
 //_____________________________________________________________________
 
// does horisontal (energy-dispersive binning)

function WaveDoBinXProc (ctrlName)
	String ctrlName
	
	String sCurDataFolder = GotoDataFolder()
	variable i = 0, j = 0, k =0, n = 0, l = 0
	String sWaveName = ImageNameList("",";") // get image name on the graph
	Variable nHorSize = 0;
	Variable nVertDim  = 0;
	if (strlen (sWaveName) == 0) // if no images (2D Matrixes) on top graph
		sWaveName = TraceNameList("",";",1) // get list of all 1D waves from the top graph
		if (strLen(CsrInfo(A)) != 0) //if csr A on one of the graphs
			sWaveName = CsrWave(A)
		endif 
	endif	
	controlinfo $("WaveBin1D")
	variable nbin = str2num(s_value)
		
	for (n = 0; n < ItemsInList(sWaveName); n += 1)
		
		Wave wCurMatrixWave = $(StringFromList(n,sWaveName))
		nHorSize =  DimSize(wCurMatrixWave,1)
		nHorSize = nHorSize ? nHorSize : 1
		make /O/N = (DimSize(wCurMatrixWave,0) / nbin, DimSize(wCurMatrixWave, 1)) $(NameOfWave(wCurMatrixWave) + "bH" + num2str(nBin))

		setScale x,  DimOffset(wCurMatrixWave,0), DimSize (wCurMatrixWave,0) * DimDelta (wCurMatrixWave,0) +  DimOffset(wCurMatrixWave,0), $(NameOfWave(wCurMatrixWave) + "bH" + num2str(nBin)) // rescale copy wave
	
		Wave wBinWave =  $(NameOfWave(wCurMatrixWave) + "bH" + num2str(nBin))
		make /O /N = (nHorSize) $("tempwave")
		Wave wTempWave = $("tempwave")
	
		//print NameOfWave (wBinWave)
		for (j = 0; j < DimSize(wCurMatrixWave,0); j += nBin)		
			for (k = j; k < j +  nBin; k += 1)
	
				for (i = 0; i < nHorSize; i += 1) 
					wTempWave[i] += wCurMatrixWave [k][i]
				endfor
				l+=1
			endfor		
			wTempWave /= l	
			for (i = 0; i < nHorSize; i += 1) // then copy copy wave into new matrix
				wBinWave [j / nBin][i] = wTempWave[i]
			endfor
			l = 0	
			wTempWave = 0			
		endfor
	endfor
	Display; 
	if (DimSize (wBinWave, 1))
		AppendImage $NameOfwave(wBinWave)
	else
		AppendToGraph $NameOfwave(wBinWave)
	endif
	SetDataFolder (sCurDataFolder)
	//AppendToGraph wBinWave
end

//____________________________________________________________________________________

// duplicate waves from the top gpaph

function WaveDupl(ctrlName)
	String ctrlName
	//print ctrlName
	if (cmpstr(ctrlName, "WaveDuplCurs") == 0)
		Wave wCW = CsrWaveRef(A)
			if (!WaveExists(wCW))
				return 0
			endif
			duplicate /O $(NameOfWave(wCW)) $(NameOfWave(wCW) + "D")
			AppendToGraph $(NameOfWave(wCW) + "D")
	endif
	
	if (cmpstr(ctrlName, "WaveDuplAll") == 0)
		variable idx = 0
		variable IfImg = 1
		String sWaveList = ImageNameList("",";") // get image name on the graph
		if (strlen (sWaveList) == 0)
			sWaveList = TraceNameList("",";",1)
			ifImg = 0
		endif	
		Display
		for (idx = 0; idx < ItemsInList(sWaveList); idx += 1)
			Wave wCW = $(StringFromList(idx, sWaveList))
			duplicate /O $(NameOfWave(wCW)) $(NameOfWave(wCW) + "D")
			if (ifImg)
				AppendImage $(NameOfWave(wCW) + "D")
			else
				AppendToGraph $(NameOfWave(wCW) + "D")
			endif
		endfor
	endif
end

//________________________________________________________________________

// save specs data in xy format (many *.txt files)
function SaveSpecsWaves()
	String sListOfWaves = WaveList("*", ";", "")
	Variable idx = 0
	String sAs = ""
	string fileNameStr
	NewPath/O path
	//abort
	for (idx = 0; idx < ItemsInList(sListOfWaves); idx += 1)
		Wave wWave = $(StringFromList(idx, sListOfWaves))
		sAs = NameOfWave (wWave) + ".txt"
		//sAs = "Save /G/W  " + NameOfWave(wWave) + " as \"" + NameOfWave(wWave) + ".txt\""	
		Save/G/M="\r\n"/W/U={1,1,0,0} /P = path wWave as sAs
	endfor

end
//__________________________________________________

// create wave with linear temperature

Macro MakeLinTemp (pnt1,tmp1,pnt2,tmp2,lngth)
Variable pnt1,tmp1,pnt2,tmp2,lngth
prompt pnt1,"number of 1 point"
prompt tmp1, "temperature at 1 point"
prompt pnt2,"number of 2 point"
prompt tmp2, "temperature at 2 point"
prompt lngth, "Number od datapoints"

String DataFolderName=GetDataFolder(0)
String TmpWaveName=DataFolderName[0,strlen(DataFolderName)-3]+"temp"
make /O /N=(lngth+1) $TmpWaveName
Variable a=(tmp1-tmp2)/(pnt1-pnt2)
Variable b=tmp1-pnt1*a
$TmpWaveName=a*(x+1)+b
//print TmpWaveName


end
//___________________________________________________

// show single spectra (single line or averaged between several lines) from  2D graph
function XPSFit_ShowWaveFromImageFunk(ctrlName)
	String ctrlName
	
	String sCurDataFolder = GotoDataFolder()

	Wave /Z wCurWave = ImageNameToWaveRef("", StringFromList(0,ImageNameList("",";")))

	if (WaveExists(wCurWave) == 0)
		SetDataFolder sCurDataFolder
	endif

	variable nFrom, nTo, nStep, nOper
	
	if(stringmatch(ctrlName, "ShowWaveFromImageCursAll"))
		nFrom = 0
		nTo = DimSize(wCurWave,1)
		nStep = 0
		nOper = 2
	else
		if (strlen(csrwave(A)) == 0)
			SetDataFolder sCurDataFolder
			Abort ("no cursor A on the top graph")
		endif
		
		variable nA = qcsr(A)
		nFrom = nA
		nTo = nA + 1
	
		strswitch(ctrlName)
			case "ShowWaveFromImageCursA":
				nStep = 0
				nOper = 0
				break
					
			case "ShowWaveFromImageCursAB":	
				nOper = 1
				if (strlen(csrwave(B)) != 0 )
					variable nB = qcsr(B)
				else 
					nB = nA
				endif
				
				nTo = abs(nB-nA)
				break
		endswitch
	endif

	string sList =  XPSFit_ShowWaveFromImage(wCurWave, nFrom, nTo, nOper)
	
	XPSFit_DisplayResults(sList)
	
	SetDataFolder sCurDataFolder	
	
end
	
	
function /S XPSFit_ShowWaveFromImage(wCurWave, nFrom, nTo, nOper) // nOper: 0 - csr A; 1 - csr AB; 2 - Csr all
	wave wCurWave
	variable nFrom, nTo, nOper
	
	switch(nOper)
		case 0:
			variable nStep = 0
			break
		
		case 1:
			nStep = nTo
			nTo = nFrom +1
			break
			
		case 2:
			nStep = 0
			break		
			
	endswitch
	
	if(nFrom > nTo)
		nTo += nFrom
		nFrom = nTo - nFrom
		nTo -= nFrom
	endif
	
	variable idx
	variable idy 
	string sList = ""	
	
	for(idx = nFrom; idx < nTo; idx += 1)
		Make /O/N = (DimSize(wCurWave,0)) $(NameOfWave(wCurWave) + "_" + num2str(idx + 1))
		wave w = $(NameOfWave(wCurWave) + "_" + num2str(idx + 1))
		
		w = 0
		setScale x,  DimOffset(wCurWave,0), DimSize (wCurWave,0) * DimDelta (wCurWave,0) +  DimOffset(wCurWave,0), $(NameOfWave(wCurWave) + "_" + num2str(idx + 1)) // rescale copy wave
		
		for(idy = idx; idy <= idx + nStep; idy += 1)
			w[] += wCurWave[p][idy] 
		endfor
		w /= nStep + 1
		sList += NameOfWave(w) + ";"
	endfor
	
	return sList

end

//_________________________________________________

// creates dialog with procedure parameters, including manipulation with coefficients
function SetXPSQFWParameters()
	
	Create_QuickFileViewr_Globals()
	
	string sDF = GetDataFOlder (1)
	SetDataFOlder $("root:XPS_QuickFileViewer")

	SVAR g_NamePrefix = root:XPS_QuickFileViewer:g_NamePrefix
	String sNamePrefix = g_NamePrefix
	
	NVAR g_bOverWriteWave = root:XPS_QuickFileViewer:g_bOverWriteWave
	variable bOverWriteWave = g_bOverWriteWave
	
	NVAR g_bKeepSwepsXML = root:XPS_QuickFileViewer:g_bKeepSwepsXML
	variable bKeepSwepsXML = g_bKeepSwepsXML
	
	NVAR g_nEnergyC = root:XPS_QuickFileViewer:g_ColumnE
	
	NVAR g_nIntC = root:XPS_QuickFileViewer:g_ColumnInt	
	
	NVAR bLoadTimeDate = root:XPS_QuickFileViewer:g_bLoadTimeDate
	
	NVAR bUseFileName = root:XPS_QuickFileViewer:g_bUseFileName
	
	SVAR g_sMakeMatrixMethod = root:XPS_QuickFileViewer:g_sMakeMatrixMethod
	string sMakeMatrixMethod = g_sMakeMatrixMethod	
	
	SVAR g_sSCIENTASweepStr = root:XPS_QuickFileViewer:g_sSCIENTASweepStr
	String sSCIENTASweepStr = g_sSCIENTASweepStr
	
	
	
	
	
	SVAR g_FITSPE = root:XPS_QuickFileViewer:g_FITSPE
	wave  /Z wFITSLoadSelList
	wave /T/Z wFITSLoadList
	wave  /Z wFITSNameSelList
	wave /T/Z wFITSNameList

	Make /T/O /N=(25) $("wFITSLoadList")
	Make /O /N=(25) $("wFITSLoadSelList")
	Make /T/O /N=(25) $("wFITSNameList")
	Make /O /N=(25) $("wFITSNameSelList")
	wave  /Z wFITSLoadSelList
	wave /T/Z wFITSLoadList
	wave  /Z wFITSNameSelList
	wave /T/Z wFITSNameList
	//endif
	
	wFITSLoadSelList = 18
	wFITSNameSelList = 18
	
//	Variable ColumnE = 	g_ColumnE				
//	Variable ColumnInt = g_ColumnInt

	
	NewPanel /K = 1 /W= (0,0,452, 450)
	Popupmenu VarGroups, title = "Parameter groups:", pos = {150,1}, size = {300, 20}, mode = 1, value = "Globals;FITS parameters;Coefficients;", proc = XPSFit_VarGroupsf

	TitleBox tb1 pos={100,40},size={300,15}, frame = 0, title="Name prefix (for file names starting with a number)", disable = 0
	SetVariable setvar1,pos={10,40},size={83,15},side = 1, title="", value = _STR:sNamePrefix, disable = 0
	
	CheckBox cb1, pos={80,60},size={351,15},title=" Ovetwrite waves during load  ", side = 0, value = bOverWriteWave, proc = XPSFit_SettingsCBSet
	
	CheckBox cb2,pos={80,80},size={351,15},title=" Keep individual sweeps for Specs XML  ", side = 0, value = bKeepSwepsXML, proc = XPSFit_SettingsCBSet, disable = 0
	
	TitleBox tb2, pos = {100, 100}, frame = 0, title = "Energy column", disable = 0
	SetVariable setvar2, pos = {46, 100}, size = {50,15},  value = _NUM:g_nEnergyC, disable = 0
	
	TitleBox tb3, pos = {100, 120}, frame = 0, title = "Data column", disable = 0
	SetVariable setvar3, pos = {46, 120}, size = {50,15},  value = _NUM:g_nIntC, disable = 0

	CheckBox cb3, pos = {80,140}, title = " Display Time and Date ", side = 0, size = {251,15}, value = bLoadTimeDate, proc = XPSFit_SettingsCBSet

	CheckBox cb4, pos ={80,160}, title = " Use file name as base name", side = 0, size = {250,15}, value = bUseFileName, proc = XPSFit_SettingsCBSet

	TitleBox tb4, pos = {100, 180}, frame = 0, title = "Make Matrix Method", disable = 0
	PopUpMenu ppm4,pos={15,180},size={90,15}, value = "Truncate;Extend;",popvalue = sMakeMatrixMethod, mode = 1, proc = XPSFit_SettingsPUMSet

	TitleBox tb5, pos = {100, 200}, frame = 0, title = "Name of SCIENTA Sweep Info Parameter", disable = 0
	SetVariable setvar5, pos = {10, 200}, value = _STR:sSCIENTASweepStr, size = {83,15} 
	
	
	
	SetVariable setvarFITSPE,pos={1,20},size={351,15},title="Name of photon energy wave for FITS", value = _STR: g_FITSPE, disable = 1
	LIstBox listFITSLoads, pos = {1,45}, size = {200,400},listWave = wFITSLoadList, selWave = 	wFITSLoadSelList , mode= 10, disable = 1
	LIstBox listFITSNames, pos = {250,45}, size = {200,400},listWave = wFITSNameList, selWave = 	wFITSNameSelList , mode= 10, disable = 1
	
	setDataFolder $sDF
	
	if (WaveExists(wCoef2DWave))
		duplicate /O wCoefNamesWave wLeftCoefList
		duplicate/O  wCoefNamesWave wRightCoefList
		Make /O /N=(DimSize(wLeftCoefList,0)) $("wLeftCoefSelList")
		Make /O /N=(DimSize(wLeftCoefList,0)) $("wRightCoefSelList")
		Wave wLeftCoefSelList = $("wLeftCoefSelList")
		Wave wRightCoefSelList = $("wRightCoefSelList")	
		wLeftCoefSelList = 0
		wRightCoefSelList = 0	
	endif
	
	if (WaveExists(wCoef2DWave))
	sort /A wLeftCoefList, wLeftCoefList
	sort /A wRightCoefList, wRightCoefList
	LIstBox list0, pos = {1,45}, size = {200,400},listWave = wLeftCoefList, selWave = 	wLeftCoefSelList, mode= 10, disable = 1
	ListBox list1, pos = {250,45}, size = {200,400},listWave = wRightCoefList, selWave = 	wRightCoefSelList, mode= 10	, disable = 1
	Button button0,pos={205,45},size={20,15},title="x", proc = OnParamDeleteLeft, disable = 1
	Button button1,pos={230,45},size={20,15},title="x", proc = OnParamDeleteRight, disable = 1
	Button button2,pos={205,115},size={41,30},title=">>",fSize=20, proc = OnCopyLeftToRight, disable = 1
	Button button3,pos={205,150},size={41,30},title="<<",fSize=20, proc = OnCopyRightToLeft, disable = 1
	PopupMenu popup0,pos={4,22},size={49,20}, mode=1,popvalue="",value= GetListOfDataFOlders(), popvalue = GetDataFolder(1), proc = OnParamPopup, disable = 1
	PopupMenu popup1,pos={250,22},size={49,20}, mode=1,popvalue="",value= GetListOfDataFOlders(), popvalue = GetDataFolder(1), proc = OnParamPopup, disable = 1
	
	
	endif
	
	button button4, pos={205,415}, size = {41,30}, title = "Save", proc = OnParamSave
	
	
	//print  GetDataFolder(1)
end

Function XPSFit_SettingsPUMSet (ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string
	
	SVAR gsMakeMatrixMethod = root:XPS_QuickFileViewer:g_sMakeMatrixMethod
	
	if  (stringmatch (ctrlName, "ppm4"))
		controlinfo pmMakeMatrix
		gsMakeMatrixMethod = s_value		
	endif
	
end

Function XPSFit_SettingsCBSet (ctrlName,bChecked) : CheckBoxControl
	String ctrlName
	Variable bChecked	

	NVAR bDisplayWArithmRes = root:XPS_QuickFileViewer:g_bDisplayWArithmRes
	NVAR bAppendWArithmRes = root:XPS_QuickFileViewer:g_bAppendWArithmRes
	NVAR bLoadTimeDate = root:XPS_QuickFileViewer:g_bLoadTimeDate
	NVAR bUseFileName = root:XPS_QuickFileViewer:g_bUseFileName
	NVAR bOverWriteWave = root:XPS_QuickFileViewer:g_bOverWriteWave
	NVAR bKeepSwepsXML = root:XPS_QuickFileViewer:g_bKeepSwepsXML
	SVAR gsMakeMatrixMethod = root:XPS_QuickFileViewer:g_sMakeMatrixMethod
	
	strswitch (ctrlName)
		case "cb1":
			controlinfo cb1
			bOverWriteWave = v_value 
			break
		
		case "cb2":
			controlinfo cb2
			bKeepSwepsXML = v_value 
			break
		
		case "ppm4":
			controlinfo ppm4
			gsMakeMatrixMethod = s_value
			break	

		case "cb3":
			bLoadTimeDate = bChecked
			break
			
		case "cb4":
			bUseFileName = bChecked
		
		case "cbAppendRes":
			bAppendWArithmRes = bChecked
			
		case "cbDisplayRes":
			bDisplayWArithmRes = bChecked
	endswitch
	
end



//_____________________________________________________
function XPSFit_VarGroupsf(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	TitleBox tb1,  disable = (popNum != 1)
	SetVariable setvar1,  disable = (popNum != 1)
	
	CheckBox cb1,  disable = (popNum != 1)
	
	CheckBox cb2,  disable = (popNum != 1)
	
	TitleBox tb2,  disable = (popNum != 1)
	SetVariable setvar2,  disable = (popNum != 1)
	
	TitleBox tb3,  disable = (popNum != 1)
	SetVariable setvar3,  disable = (popNum != 1)

	CheckBox cb3,  disable = (popNum != 1)

	CheckBox cb4,  disable = (popNum != 1)

	TitleBox tb4,  disable = (popNum != 1)
	PopUpMenu ppm4, disable = (popNum != 1)

	TitleBox tb5,  disable = (popNum != 1)
	SetVariable setvar5,  disable = (popNum != 1)
	
	SetVariable setvarFITSPE, disable = (popNum != 2)
	LIstBox listFITSLoads, disable = (popNum != 2)
	LIstBox listFITSNames, disable = (popNum != 2)
	
	if (WaveExists(wCoef2DWave))
		LIstBox list0, disable = (popNum != 3)
		ListBox list1,  disable = (popNum != 3)
		Button button0, disable = (popNum != 3)
		Button button1, disable = (popNum != 3)
		Button button2, disable = (popNum != 3)
		Button button3, disable = (popNum != 3)
		PopupMenu popup0, disable = (popNum != 3)
		PopupMenu popup1, disable = (popNum != 3)
	endif
	
	
	
end
//_______________________________________________________
// copies coefficient form left folder of the parameter dialog to right one
function OnCopyLeftToRight(ctrlName)
	string ctrlName

	string sDF = GetDataFolder(1)
	ControlInfo $("popup0")
	string sODF = s_value
	ControlInfo $("popup1")
	string sNDF = s_value
	
	if (!stringmatch(sODF,"root:"))
		sODF = sODF[0,strlen(sODF) - 2]
	endif
	
	if (!stringmatch(sNDF,"root:"))
		sNDF = sNDF[0,strlen(sNDF) - 2]
	endif
	
	variable idx = 0
	
	do
		SetDataFolder $sODF
		Wave wLeftCoefSelList = $("wLeftCoefSelList")
		Wave/T wLeftCoefList = $("wLeftCoefList")
		
		if (idx > DimSize (wLeftCoefSelList,0))
			break
		endif
	
		if (wLeftCoefSelList[idx])
			Wave wCoefWave = GetCoefWave(wLeftCoefList[idx])
			SetDataFolder $sDF
	
			if (strsearch(sODF, "root",0) == -1)
				sODF = ":" + sODF + ":"
			endif
	
			if (strsearch(sNDF, "root",0) == -1)
				//print sNDF
				if (!stringmatch(sNDF[0],":") )
					sNDF = ":" + sNDF + ":"
				else
					sNDF =  sNDF + ":"
				endif
			endif
			
			//print  sNDF
			MoveWave $(sODF + NameOfWave(wCoefWave)) ,  $(sNDF  + NameOfWave(wCoefWave)) 
			MoveWave $(sODF + "Link_" + NameOfWave(wCoefWave)[5,strlen(NameOfWave(wCoefWave))]) ,  $(sNDF  + "Link_" + NameOfWave(wCoefWave)[5,strlen(NameOfWave(wCoefWave))]) 
			MoveWave $(sODF + "LinkV_" + NameOfWave(wCoefWave)[5,strlen(NameOfWave(wCoefWave))]) ,  $(sNDF  + "LinkV_" + NameOfWave(wCoefWave)[5,strlen(NameOfWave(wCoefWave))])
			
			if (!stringmatch(sODF,"root:"))
				sODF = sODF[0,strlen(sODF) - 2]
			endif
			
			if (!stringmatch(sNDF,"root:"))
				sNDF = sNDF[0,strlen(sNDF) - 2]
			endif
			
			SetDataFolder $sNDF
			SaveCoefWave(NameOfWave(wCoefWave))
			SetDataFolder $sDF
		else
			SetDataFolder $sDF
		endif
		idx += 1
	while (1)
	SetDataFolder $sDF	
end

// copies coefficient from left folder of the prarameter dialog to the right one
function OnCopyRightToLeft(ctrlName)
	string ctrlName

	string sDF = GetDataFolder(1)
	ControlInfo $("popup1")
	string sODF = s_value
	ControlInfo $("popup0")
	string sNDF = s_value
	
	if (!stringmatch(sODF,"root:"))
		sODF = sODF[0,strlen(sODF) - 2]
	endif
	
	if (!stringmatch(sNDF,"root:"))
		sNDF = sNDF[0,strlen(sNDF) - 2]
	endif
	
	variable idx = 0
	
	do
		SetDataFolder $sODF
		Wave wRightCoefSelList = $("wRightCoefSelList")
		Wave/T wRightCoefList = $("wRightCoefList")
		if (idx > DimSize (wRightCoefSelList,0))
			break
		endif
	
		if (wRightCoefSelList[idx])
			Wave wCoefWave = GetCoefWave(wRightCoefList[idx])
			SetDataFolder $sDF
	
			if (strsearch(sODF, "root",0) == -1)
				sODF = ":" + sODF + ":"
			endif
	
			if (strsearch(sNDF, "root",0) == -1)
				sNDF = ":" + sNDF + ":"
			endif
		
			MoveWave $(sODF + NameOfWave(wCoefWave)) ,  $(sNDF  + NameOfWave(wCoefWave)) 
			MoveWave $(sODF + "Link_" + NameOfWave(wCoefWave)[5,strlen(NameOfWave(wCoefWave))]) ,  $(sNDF  + "Link_" + NameOfWave(wCoefWave)[5,strlen(NameOfWave(wCoefWave))]) 
			MoveWave $(sODF + "LinkV_" + NameOfWave(wCoefWave)[5,strlen(NameOfWave(wCoefWave))]) ,  $(sNDF  + "LinkV_" + NameOfWave(wCoefWave)[5,strlen(NameOfWave(wCoefWave))])
			
			if (!stringmatch(sODF,"root:"))
				sODF = sODF[0,strlen(sODF) - 2]
			endif
			
			if (!stringmatch(sNDF,"root:"))
				sNDF = sNDF[0,strlen(sNDF) - 2]
			endif
			
			SetDataFolder $sNDF
			SaveCoefWave(NameOfWave(wCoefWave))
			SetDataFolder $sDF
		else
			SetDataFolder $sDF
		endif
		idx += 1
	while (1)
	SetDataFolder $sDF	
end

//_____________________________________________________

// save parameters
function OnParamSave(ctrlName)
	String ctrlName
	
	NVAR g_ColumnE = root:XPS_QuickFileViewer:g_ColumnE
	NVAR g_ColumnInt = root:XPS_QuickFileViewer:g_ColumnInt
	SVAR g_NamePrefix = root:XPS_QuickFileViewer:g_NamePrefix
	SVAR g_FITSPE = root:XPS_QuickFileViewer:g_FITSPE
	
	ControlInfo $("setvar2")
	g_ColumnE = v_value
	ControlInfo $("setvar3")
	g_ColumnInt = v_value
	ControlInfo $("setvar1")
	g_NamePrefix = s_value	
	ControlInfo $("setvarFITSPE")
	g_FITSPE = s_value	
	
	XPSFit_SaveGlobals()
	
end

//________________________________________________________

// displays list of coefficients from a folder
function OnParamPopup (ctrlName,PopNum,popStr) : PopupMenuControl 
	String ctrlName
	Variable PopNum
	String popStr
		
	string sDF = GetDataFolder(1)
	if (!stringmatch(popStr,"root:"))
		popStr = popStr[0,strlen(popStr) - 2]
	endif
	SetDataFolder $popStr
	if (stringmatch(ctrlName,"popup0"))
		if (WaveExists(wCoef2DWave))
			duplicate /O wCoefNamesWave wLeftCoefList
		else
			make /O/T/N= 1 $("wLeftCoefList")
		endif
		Make /O /N=(DimSize(wLeftCoefList,0)) $("wLeftCoefSelList")
		Wave wLeftCoefSelList = $("wLeftCoefSelList")
		wLeftCoefSelList = 0
		sort /A wLeftCoefList, wLeftCoefList
		LIstBox list0, pos = {1,45}, size = {200,350},listWave = wLeftCoefList, selWave = 	wLeftCoefSelList, mode= 10
	endif
	if (stringmatch(ctrlName,"popup1"))
		if (WaveExists(wCoef2DWave))
			duplicate /O wCoefNamesWave wRightCoefList
		else
			make /O/T/N= 1 $("wRightCoefList")
		endif
		Make /O /N=(DimSize(wRightCoefList,0)) $("wRightCoefSelList")
		Wave wRightCoefSelList = $("wRightCoefSelList")
		wRightCoefSelList = 0
		sort /A wRightCoefList, wRightCoefList
		ListBox list1, pos = {250,45}, size = {200,350},listWave = wRightCoefList, selWave = 	wRightCoefSelList, mode= 10	
	endif
	
	SetDataFolder $sDF
	
end
//____________________________________________________

// deletes coefficient from left folder
function OnParamDeleteLeft(ctrlName)
	string ctrlName
	
	string sDF = GetDataFOlder(1)
	ControlInfo $("popup0")
	if (!stringmatch(s_value,"root:"))
		s_value = s_value[0,strlen(s_value) - 2]
	endif
	
	SetDataFolder $s_value
	variable idx = 0
	Wave wLeftCoefSelList = $("wLeftCoefSelList")
	Wave/T wLeftCoefList = $("wLeftCoefList")
	do
		if (idx >= DimSize (wLeftCoefSelList,0))
			break
		endif
		if (wLeftCoefSelList[idx])
			DeletePoints /M=1 FindStrInWave(wLeftCoefList[idx],wCoefNamesWave), 1, $("wCoef2DWave")
			DeletePoints FindStrInWave(wLeftCoefList[idx],wCoefNamesWave), 1, $("wCoefNamesWave")
			
		endif
		idx += 1
		 
	while(1)
	duplicate /O wCoefNamesWave $("wLeftCoefList")
	Make /O /N=(DimSize(wLeftCoefList,0)) $("wLeftCoefSelList")
	Wave wLeftCoefSelList = $("wLeftCoefSelList")
	sort /A wLeftCoefList, wLeftCoefList
	LIstBox list0, pos = {1,65}, size = {200,350},listWave = wLeftCoefList, selWave = 	wLeftCoefSelList, mode= 10
	
	SetDataFolder $sDF
end

//  deletes coefficient form right folder
function OnParamDeleteRight(ctrlName)
	string ctrlName
	
	string sDF = GetDataFOlder(1)
	ControlInfo $("popup1")
	if (!stringmatch(s_value,"root:"))
		s_value = s_value[0,strlen(s_value) - 2]
	endif
	SetDataFolder $s_value
	variable idx = 0
	Wave wRightCoefSelList = $("wRightCoefSelList")
	Wave/T wRightCoefList = $("wRightCoefList")
	do
		if (idx >= DimSize (wRightCoefSelList,0))
			break
		endif

		if (wRightCoefSelList[idx])
			DeletePoints /M=1 FindStrInWave(wRightCoefList[idx],wCoefNamesWave), 1, $("wCoef2DWave")
			DeletePoints FindStrInWave(wRightCoefList[idx],wCoefNamesWave), 1, $("wCoefNamesWave")			
		endif

		idx += 1
	while(1)
	duplicate /O wCoefNamesWave $("wRightCoefList")
	Make /O /N=(DimSize(wRightCoefList,0)) $("wRightCoefSelList")
	Wave wRightCoefSelList = $("wRightCoefSelList")
	sort /A wRightCoefList, wRightCoefList
	ListBox list1, pos = {250,65}, size = {200,350},listWave = wRightCoefList, selWave = 	wRightCoefSelList, mode= 10	
	
	SetDataFolder $sDF
end

//___________________________________________________
function /S GetListOfDataFOlders()
	
	DFREF refCurFolder = GetDataFolderDFR()
	variable idx = 0
	string sListOfDFolders = GetDataFolder(1) + ";"
	string sDF
	do 
		sDF = GetIndexedObjNameDFR(refCurFolder, 4, idx)
		if (strlen(sDF) == 0)
			break
		endif
		sListOfDFolders += sDF + ":;"
		idx += 1
	while (1)
	return sListOfDFolders
end

//_____________________________________________________

//	sums images

//function SumImages(sListOfImg)
//	String sListOfImg/
	
//	variable nNumOfImg = ItemsInList(sListOfImg)
	
//	duplicate /O $(StringFromList(0,sListOfImg)), $(StringFromList(0,sListOfImg) + "aver")//
//	wave wAverImg = $(StringFromList(0,sListOfImg) + "aver")
//	variable i,j,k
//	//print sListOfImg
//	for (k = 1; k < nNumOfImg; k+= 1)
//		wave wAverWave = $(StringFromList(k,sListOfImg))
//		print StringFromList(k,sListOfImg)
//		for (i = 0; i < DimSize(wAverWave,0); i += 1 )
//			for(j = 0; j < DimSize(wAverWave,1); j += 1)
//				wAverImg[i][j] += wAverWave[i][j]
//			endfor
//		endfor
//	endfor
//	wAverImg /= nNumOfImg
//end
//__________________________________________

//renames waves

function ReNameList (sRenameFrom, sRenameTo)
	string sRenameFrom, sRenameTo
	

	prompt sRenameFrom, "From"
	prompt sRenameTo, "To"
	DoPrompt "Rename waves", sRenameFrom, sRenameTo
	
	if (v_flag == 1)
		return 0
	endif
	
	string sWaveList = WaveList ("*" + sRenameFrom + "*", ";", "")
	variable i = 0
	string sWaveName, sNewWaveName
	
	for (i = 0; i < ItemsInList(sWaveList); i += 1)
		sWaveName = StringFromList(i, sWaveList)
		sNewWaveName = replacestring (sRenameFrom, sWaveName, sRenameTo )
		if (!WaveExists($sNewWaveName))
			rename $sWaveName $sNewWaveName
		endif
	endfor
	
end

//_____________________________________________

function XPSFit_MakeFETable()

	string sWaveList = WaveList("*", ";", "WIN:")
	wave w = $StringFromList(0,sWaveList)
	
	if(DimSize(w,1))
		Variable nDimSize = DimSize(w,1)
	else
		nDimSize = ItemsinList(sWaveList)	
	endif
	
	string s = StringFromList(0,sWaveList)
	variable nNum = strsearch(s,"_",strlen(s)-1,1)
	string st =  s[nNum+1,strlen(s)-1]
	
	if (48>char2num(st[0]) || 57 < char2num(st[0]))
		variable nNum1 = strsearch(s,"_",nNum-1,1)
		string sFEWaveName = "FERMI_" + s[nNum1+1,nNum-1]	
	else
		sFEWaveName = "FERMI_" + s[nNum+1,strlen(s)-1]	
	endif
	
	
	Prompt sFEWaveName, "Name of new FE table"
	DoPrompt "Wave Name", sFEWaveName
	
	if(V_flag == 1)
		abort
	endif
	
	if (WaveExists($sFEWaveName))
		DoAlert 1, "Wave Exists. Replace wave?"
		if (V_flag == 2) // no clicked
			abort
		endif
	endif
	
	Make /T/O/N=(nDimSize,2), $sFEWaveName
	wave/T wF = $sFEWaveName
	
	variable idx
	string sWave
	
	for(idx = 0; idx < nDimSize; idx += 1)
		if(DimSize(w,1))
			sWave = NameOfWave(w) + "_" + num2str(idx + 1)
		else
			sWave = stringfromlist(idx,sWaveList)
		endif
			wF[idx][0] = sWave
			wF[idx][1] = "0" 
	endfor
	

	Edit
	AppendToTable $sFEWaveName
	
end


function	XPS_QuickViewer_Update()	
	
end

//______________________________________________


function XPSFit_SaveGlobals()
	
	string sDF = GetDataFOlder(1)
	
	if (!DatafolderExists("root:XPS_QuickFileViewer"))
		abort
	endif
	close /A
	SetDataFolder root:XPS_QuickFileViewer
	newpath /O path (":User Procedures:")
	variable refnum	
	Open /Z/P=path refNum as ("XPSFitConfig.cfg")
	if (!v_flag)
	
	variable nNumObj
	variable idx, i, j
	string s
	
	string sObjName
	
	for (i = 1; i <= 3; i += 1)
		 nNumObj = CountObjects("",i)
		
		for (idx = 0; idx < nNumObj; idx+= 1)
			sObjName = GetIndexedObjName("",i,idx)
			if (stringmatch("wHistory",sObjName))
				continue
			endif
			switch (i)
				case 1: // waves
					wave w = $sObjName	
					s = NameOfWave(w) + " = "
					for (j = 0; j < DimSize(w, 0); j += 1)
						switch (WaveType(w,1))
							case 1: // numeric
								s += num2str(w[j]) + ";"
								break
							case 2: //  text
								wave/T wS = $sObjName
								s += wS[j] + ";"
								break
						endswitch
					endfor	
					s = s[0,397] + ";\n"
					
					fprintf refNum, s
					break
				case 2:
					nvar nObj = $sObjName
					fprintf refnum,(sObjName + " = " + num2str(nObj) + "\n")
					break
				case 3:
					svar sObj = $sObjName
					fprintf refnum, sObjName + " = " + sObj + "\n"
					break		
			endswitch

			
		endfor
	endfor
	endif
	
	close refnum
	
	SetDataFolder sDf
end


function XPSFit_LoadGlobals()
	string sDF = GetDataFOlder(1)
	
	if (!DatafolderExists("root:XPS_QuickFileViewer"))
		abort
	endif
	close /A
	SetDataFolder root:XPS_QuickFileViewer
	
	string spath = ":User Procedures:"
	string sname = "XPSFitConfig.cfg"
	
	newpath /O path spath
	variable refnum
	Open /R/Z/P=path refNum as sName
	
	if (v_flag != 0)
		Close /A
		SetDataFolder sDF
		return v_flag	
	endif

	string str
	
	//print  "vflag:", v_flag

	//if (v_flag == 0)
	
	variable nNumObj
	variable idx, i, j
	string s
	
	string sObjName
	
	for (i = 1; i <= 3; i += 1)
		 nNumObj = CountObjects("",i)
		
		for (idx = 0; idx < nNumObj; idx+= 1)
			sObjName = GetIndexedObjName("",i,idx)
		//print sObjName
			switch (i)
				case 1: // waves
					wave w = $sObjName	
					str = XPSFit_FGetVar(spath,sName, sObjName)
					
					if(!strlen(str))
						continue
					endif
					

					for (j = 0; j < DimSize(w, 0); j += 1)
						switch (WaveType(w,1))
							case 1: // numeric
								w[j] = str2num(stringfromlist(j,str))
								break
							case 2: //  text
								wave/T wS = $sObjName
								wS[j] = (stringfromlist(j,str))
								break
						endswitch
					endfor	
					break
				case 2:
					nvar nObj = $sObjName
					str = XPSFit_FGetVar(spath,sName, sObjName)
					if (!strlen(str))
						str = "0"
					endif
					nObj = str2num(str)
					break
				case 3:
					svar sObj = $sObjName
					sObj = XPSFit_FGetVar(spath,sName, sObjName)
					//print sObjName, sObj
					break		
			endswitch

			
		endfor
	endfor
//	close refnum
//	endif
	
	
	
	SetDataFolder sDf
	return v_flag
end


function /T XPSFit_FGetVar(spath,sName, sVarName)
	string spath,sName, sVarName
	
	newpath /O path spath
	variable refnum
	Open /R/Z/P=path refNum as sName
	
	
	string str
	string sVarVal
	
	//print sVarName
	FReadLine refNum, str
	
	if (!strlen(str))
		return ""
	endif
	
	do
		if (strsearch (str, sVarName, 0) != -1)
			sVarVal = str[strlen(sVarName) + 3, strlen(str) - 2]
			//print sVarName, sVarVal//, str
			break
		else
			sVarVal = ""
		endif
	FReadLine refNum, str
	while (strlen(str))
	close refnum
	return sVarVal
end
//_________________________________________________________



function XPSFit_SaveToHistory(nPos,sWaveList,sWin,nOper,sParam,sMode)
	variable nPos // 0 - same as before; 1- new 
	string sWaveList // list of waves
	string sWin // name of the graph
	variable nOper // arithm operation
	string sParam // value for operation
	string sMode // mode of operation
	
	wave /T wHistory = root:XPS_QuickFileViewer:wHistory

	variable nLastPos = 0
	variable nLastRow = 0
	variable idx = 0
	nLastPos = str2num(wHistory[0][0])
	
	do // get last written history position
		if(str2num(wHistory[idx + 1][0]) >= str2num(wHistory[idx][0]))
			nLastPos = str2num(wHistory[idx + 1][0])
		else
			nLastRow = idx
			break
		endif
		idx+=1
	while (idx < DimSize(wHistory,0))

	nLastRow = nLastRow == DimSize(wHistory,0) ? 0 : nLastRow
	
	if(nPos)
		wHistory[nLastRow + 1][0] = num2str(nLastPos + 1)
	else
		wHistory[nLastRow + 1][0] = num2str(nLastPos)
	endif
	
	wHistory[nLastRow + 1][1] = sWaveList
	wHistory[nLastRow + 1][2] = sWin
	wHistory[nLastRow + 1][3] = num2str(nOper)
	wHistory[nLastRow + 1][4] = sParam
	wHistory[nLastRow + 1][5] = sMode

end



function XPS_UndoOperationf()
	
	SVAR sgMakeMatrixMethod = root:XPS_QuickFileViewer:g_sMakeMatrixMethod
	string sMakeMatrixMethod = sgMakeMatrixMethod
	wave /T wHistory = root:XPS_QuickFileViewer:wHistory
	
	variable nLastPos = 0
	variable nLastRow = 0
	variable idx = 0
	nLastPos = str2num(wHistory[0][0])
	
	do // get last written history position
		if(str2num(wHistory[idx + 1][0]) >= str2num(wHistory[idx][0]))
			nLastPos = str2num(wHistory[idx + 1][0])
		else
			nLastRow = idx
			break
		endif
		idx+=1
	while (idx < DimSize(wHistory,0))
	
	//print nLastRow, nLastPos
	
	// find inverse operation
	do
		nLastPos = str2num(wHistory[nLastRow][0])
		
		string sWaveList = wHistory[nLastRow][1]
		string sWin = wHistory[nLastRow][2]
		variable nOper = str2num(wHistory[nLastRow][3])
		string sParam = wHistory[nLastRow][4]
		variable nMode = str2num(wHistory[nLastRow][5])
		variable nInvOper = 0
	
		switch (nOper)
			case ARITHM_NORMAREAS:
				nInvOper = ARITHM_MULTC
				break
			
			case DIVBACK:
				nInvOper = ARITHM_MULTC
				break
			
			case SUBBACK:
				nInvOper = ARITHM_PLUSC
				break
			
			case ARITHM_PLUSB:
				nInvOper = ARITHM_MINUSB
				break
				
			case ARITHM_MINUSB:
				nInvOper = ARITHM_PLUSB
				break
				
			case ARITHM_MULTB:
				nInvOper = ARITHM_DIVB
				break
				
			case ARITHM_DIVB:
				nInvOper = ARITHM_MULTB
				break
			
			case ARITHM_PLUSC:
				nInvOper = ARITHM_MINUSC
				break
				
			case ARITHM_MINUSC:
				nInvOper = ARITHM_PLUSC
				break
				
			case ARITHM_MULTC:
				nInvOper = ARITHM_DIVC
				break
				
			case ARITHM_DIVC:
				nInvOper = ARITHM_MULTC
				break
				
			case ARITHM_BEMINUS:
				nInvOper = ARITHM_BEPLUS
				break
				
			case ARITHM_BEPLUS:
				nInvOper = ARITHM_BEMINUS
				break
			
			case ARITHM_ETOBE:
				nInvOper = ARITHM_ETOBE
				wave /T/Z wFermiWave = $sParam
				
				if(nMode == MODE_BE)
					if(WaveExists(wFermiWave))
						for(idx = 0; idx < DimSize(wFermiWave,0); idx += 1)
							wFermiWave[idx][1] = num2str(str2num(wFermiWave[idx][1]) * -1)
						endfor
					else
						sParam = num2str(-str2num(sParam))
					endif
				endif
				
				break
					
			default:
				return 0
				break
		endswitch
	
	
		//print WinList(sWin,";","")
		if(strlen(WinList(sWin,";","")))
			DoWindow /F $sWin
		
			for(idx = 0; idx < ItemsInList(sWaveList); idx += 1)
				wave w = $StringFromList(idx,sWaveList)
				if(DimSize(w,1))
					if(strsearch(ImageNameList(sWin,";"), NameOfwave(w), 0) == -1)
						NewImage $StringFromList(idx,sWaveList)
					endif
				else
					if(strsearch(TraceNameList(sWin, ";", 1), NameOfwave(w), 0) == -1)
						//print "Append"
						AppendToGraph $StringFromList(idx,sWaveList)
					endif
				endif
			endfor
		else
			wave w = $StringFromList(0,sWaveList)

			if(DimSize(w,1))
				NewImage w
			else
				Display			
				for(idx = 0; idx < ItemsInList(sWaveList); idx += 1)
					AppendToGraph $StringFromList(idx, sWaveList)
				endfor
			endif
		endif
		
		if (nInvOper == ARITHM_ETOBE)
			if(WaveExists(wFermiWave))
				sgMakeMatrixMethod = "Truncate"
				XPSFit_EToBE(sWaveList, str2num(sParam), nMode, sParam)
				sgMakeMatrixMethod = sMakeMatrixMethod
		
				If (nMode == MODE_BE )
					for(idx = 0; idx < DimSize(wFermiWave,0); idx += 1)
							wFermiWave[idx][1] = num2str(str2num(wFermiWave[idx][1]) * -1)
						endfor
				endif
			else
				XPSFit_EToBE(sWaveList, str2num(sParam), nMode, "none")
			endif
			
		else
			XPSFit_WaveArithm(sWaveList, nInvOper, sParam,nMode)
		endif
		
		wHistory[nLastRow][] = "0"
		nLastRow -= 1
		
		if (nLastRow == 0)
			if(str2num(wHistory[DimSize(wHistory,0) - 1][0]) == 0)
				return 0
			else
				nLastRow = (DimSize(wHistory,0)) - 1
			endif
		endif
		
	while (str2num(wHistory[nLastRow][0]) == nLastPos)
	
	
end


//constant NOBACK = 100
//constant SHIRLEY = 101
//constant LINEAR = 102
//constant SUBBACK = 103
//constant DIVBACK = 104
//constant ARITHM_NORMAREAS = 201
//constant ARITHM_AVERAGE = 202
//constant ARITHM_SUM = 203
//constant ARITHM_BINHOR = 204
//constant ARITHM_BINVER = 205
//constant ARITHM_PLUSB = 206
//constant ARITHM_MINUSB = 207
//constant ARITHM_MULTB = 208
//constant ARITHM_DIVB = 209
//constant ARITHM_PLUSC = 210
//constant ARITHM_MINUSC = 211
//constant ARITHM_MULTC = 212
//constant ARITHM_DIVC = 213
//constant ARITHM_BEPLUS = 214
//constant ARITHM_BEMINUS = 215
//constant ARITHM_ETOBE = 216

function XPSFit_ScientaSweepFunc()
	SVAR sSSS = root:XPS_QuickFileViewer:g_sSCIENTASweepStr
	
	string sList = TraceNameList("",";",1)
	variable idx, nSweeps
	string s
	
	for(idx = 0; idx < ItemsInList(sList); idx += 1)
		wave w = $StringFromList(idx,sList)
		s = StringByKey(sSSS, note(w), "=", "\r")
		print 	NameOfWave(w),  s, "sweeps"	
		if(strlen(s))
			nSweeps = str2num(s)
			w /= nSweeps
		endif
	endfor
	
end

proc XPSFit_BnExe (ctrlName) : ButtonControl
	String ctrlName
	
	XPSFit_BnExeFunc(ctrlName)
end

function XPSFit_BnExeFunc(ctrlName)
	String ctrlName
		
	if(stringMatch(CtrlName, "bnToC"))
		XPSFit_CountMethodToCORCPS(CMODE_C)
	elseif(stringMatch(CtrlName, "bnToCPS"))
		XPSFit_CountMethodToCORCPS(CMODE_CPS)
	endif
	
end


function XPSFit_CountMethodToCORCPS(nToMode)
	variable nToMode
	
	SVAR g_sSCIENTATime = root:XPS_QuickFileViewer:g_sSCIENTATime
	SVAR g_sSCIENTASweepStr = root:XPS_QuickFileViewer:g_sSCIENTASweepStr
	
	string sList = TraceNameList("",";", 1)
	variable idx, t, nTime, nSweeps
	variable nCMode 
	string sScale
	string sSCIENTAID = "[SES]"
	string sCountModeStr = "CountMode"
	
	for(idx = 0; idx < ItemsInlist(sList); idx +=1)
		wave w = $StringFromList(idx, sList)
		
		if(strsearch(note(w), sSCIENTAID,0) == 0)
		//	print strsearch(g_sSCIENTATime, note(w), 0), note(w)
			if(strsearch(note(w), g_sSCIENTATime, 0) == -1 || strsearch(note(w), g_sSCIENTASweepStr, 0) == -1 )
				DoAlert 1, "Scienta spectrum does not contain dwell time information or the name of parameter is wrong.\rCheck parameter names in Settings.\r\rContinue to next spectrum?" 
				
				if(v_flag == 1)
					continue
				else
					return 0
				endif
				
			endif
			
			if(strsearch(note(w), sCountModeStr,0) != -1) // identify is in c or cps
				if (stringmatch(stringbykey(sCountModeStr,note(w),"=", "\r" ),"cps"))
					nCMode = CMODE_CPS
				elseif(stringmatch(stringbykey(sCountModeStr,note(w),"=", "\r" ),"c"))
					nCMode = CMODE_C
				endif
			else // no entry - Counts
				nCMode = CMODE_C
			endif
		endif
		
		if(nCMode != nToMode)
			nTime = str2num((stringbykey(g_sSCIENTATime,note(w),"=", "\r" )))
			nTime /= 1000
			nSweeps = str2num((stringbykey(g_sSCIENTASweepStr,note(w),"=", "\r" )))
						
			switch (nToMode)
				case CMODE_C:	
					w = w * nTime * nSweeps
					sScale = "Counts"
					break
				
				case CMODE_CPS:
					w = w / nTime / nSweeps
					sScale = "Counts Per Sec"
					break
			endswitch
			
			XPSFit_CountMethodInsMethodSrt(w,nToMode)
			SetScale d 0,0, sScale, w
			
		endif
		
	endfor
	
	//print nCMode
	
end


function XPSFit_CountMethodInsMethodSrt(w,nCMode)
	wave w
	variable nCMode
	
	string sCountModeStr = "CountMode"
	string s = stringbykey(sCountModeStr,note(w),"=", "\r" )
	string sNote = note(w)
	
	if(nCMode == CMODE_C)
		string sMode = "c"
	elseif(nCMode == CMODE_CPS)
		sMode = "cps"	
	endif
	
	if(strlen(s)) // wave has info of c/cps
		sNote = ReplaceStringByKey(sCountModeStr, sNote, sMode, "=", "\r") 
		note /K w
		note w, sNote
	else // no info about c/cps
		note w, (sCountModeStr + "=" + sMode) 
	endif
	
	
	
	
	
end







//____________________________________________________
// PNG: width= 120, height= 40
Picture PicEToBE_
		ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!"D!!!!I#Qau+!4mucEW?(>&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U!M`4S5u_NKm@,g?K-1k_OYgKg+RpLZaZGl7#7p%dcJ[p;JVF_.N?\92$f=>YiPGQS'8ULi;TqI"a
	^X:`.$KuHBo,cEEjFm.p:/L;O]&%tdm47[Nr_(0.=fPZD]i5E@;sri(^]hD8fd"1Nc[@<#ucC]d6`Y
	7SoqRlO3p;_q[SX"&403IB&krj$),D@.%t@S6A)4'K;_+hW'Z,]I9/H+c/YqoYJuni.05LVm%Q+UA,
	?ZI+RU=ulkfMKeAjR!O&H^TUT)PEO1m"3Y@r8Tk/,hdi-eRq-0D>E6Ojp(@@YTiNi[DV\Bf*%*oH%!
	N_U%Wa%6TZd2>\(IkD+'X7C<p55R)t!1#%*X"s8R*P@RFm_gGJO7/:abE1<8Usr$`&63BT<G2qDBFn
	0W&63BT]PUm<0baZG[Z)b[;''f>7qklDBq!7A6BCXJjQLS'FTLh`m>6r]e:dL82Cb'5B16U<'?RA'[
	ZcFHjtZZ88E5Z%n,%65,6mACDAWRiAW1P"q%&B^ANgfhaI/!L_W,31,'J3d2pu(QP$?Zkp](9o!(fU
	S7'8jaJc
	ASCII85End
End

// PNG: width= 120, height= 40
Picture PicMatrixAnal
ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!"D!!!!I#Qau+!4mucEW?(>&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U!b"Yg5u_NKm@(_o_B9DD2jqll=tjH#C$CSIcf7)Hj#d$Z2AUK0.4jk(_7_o9@09(\,Zh]0KFL.YZ
	\/<YgU:XcPhPU#\(cn>_lD]XC%t:L7;5-r/GXem\C+)K8u6Eh:doOL"/lO#1(gp2HTWA*qmuJh%F?D
	:\ar_n>,XYPMNc:+O,%MCdDneHn;*CJOE1R]SK"^_].N(U\Ra=4@-[-&gR7"iZk.thYoKmHe`qIoRS
	W`ok;%0o6EIDr@$Z3@WLqLLe,t7Rp6iVODna6g\@:/UkT6M\0XNn$1[]BW7N^Z)bXD5nBQb`@,uN]C
	Dh7%`A!2lRJ.J@8&"R8CfSr/&3VYQ_NLV"HnJFV_+(LCcG,#TA)bE::A*Er$E</auU*^q>^ajNV_un
	#"[I0W/:uk+qKL?K7V%>KLn1e?iBB%rnoZT@(AFqU2+WnV=!/f,GMU3K'cle4m+H"MgMU3K'cle4m+
	H"Mg5(kh<OZP4tS(>k.gT[N>r+8.<h?iNES[lCp`](#BHA^M#ZDoT3XB]u4cru`m>,;9SG#>5[dF(p
	D/U`?6oe?[>H8IY<%LdjQWH>hE`5aR#om4jh1JZ%*J?ms_QfOLpirM!?f1X1#QIpVtV:L!(-$QsA>L
	(1-(`ElLF8-tI5rgB!]1JjKj`9<j7N^ZiOBZ[-kk"UdhLS[tpO04O[C,A$r)N[oYdAgKA&k682?sZq
	k2YgGG@e2?E&bcWns%gD2Q,#\LkKt4h'o/qS8Y]e-6bW%4s;'o7LC6pn+R+r*5`;Q>A]'ub1D7G!!!
	!j78?7R6=>B
	ASCII85End
End


// PNG: width= 120, height= 39
Picture PicListToMatrix
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!"D!!!!I#Qau+!4mucEW?(>&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U!h;hM5u_NKm@(;C_B9DE2]66Z/XWfMZuj=5kO9(2#A<T;^6l<fKq3W!9=l^a@rQu."BaUM^+(HK6
	@SZa%7rL=,A7?+G.ZStG(Xn09DhL"C.eg5Gsod+E^Os>re1ooKp]Nkml"*'N['2!P/H6t]jAt^J&+g
	:aU$R$nEV_*T046Vcr2,soBRYB\.qEr5\Gj53Z4e:.W-RkqTWV^4Wl&t<KKFFK"HVk0E>3-Q^>n7ZZ
	G+2cX>b2eP)JaT$M&r$(bY</+!4`X)4T%jC[DAMQHI$]l]lC_Rb>U]U&&VM<IWN4siYsGu)0sT>/;_
	;p\59HjEGn'*WX70\!3gB$uI!3X6"UM=N94XGh_`9`.^RRn8aG/?Q`^=da_H1#Xi6S!eN*<uhiSGU+
	Z8n7VlMeH(52V%6.\Z,0Yh'<eFR7A_"6.QgmCc58-)Hai[;.?aKnVkk"^jhj(rekD!#@W4f3<=ZRe>
	^l2VSC+42s!mn"s+*UU-g_F5dq5%/7]U+BUn.%e.(uN^k"g_#DK<aS7jYNDFVHQ/4STND>jBj@F&6.
	R%bCJP]nNi)1oE*r)(h+OHE"k(-+Em%8B.;&BN'`Bi2T.U@f/SZd*d7kAsuH0#;gNfr;E9Q(l;f=%L
	(?,X%C'0XjA]lXU<m2ioN_X,'$#HA5cLmhS3C#pf<WJBS\V#DR]Vi:4>?)S!jJnlS/oECT[^S"cPZJ
	cP8bdO%4>14_A/r5TP8:TB/PeAkER!pX-l4.$`=X*oe%Y@D8e&TMd<Tg%$g*a]iY=%Oo$ImmFk>U04
	\OVpbsZ&HfjZVW&79()d2N5HFItV6VAUR>S$R<hW0K_bBh%4^ist<$_,)jpMP4Z`RJT57.Aj!!#SZ:
	.26O@"J
	ASCII85End
End






// PNG: width= 120, height= 39
Picture myPictName
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!"E!!!!H#Qau+!2LTRR/d3e&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U!oQX<5u_NKjdNH3j"M%!-cY("NJY93_,ZAF.h8_rDOWc)OuHLq_@NoUYHZ?XYAeGLWeGQZ(:HdP(
	60oP/$pO:,WV<U`I4P$m'1+"UQJ$O(N6K1@*j)qG.TmW%Zh0"`ICO_O4p`A*aM*)k4#Xb;IL@+C"f`
	QIOnP8Hp6[F4I-=BKEct9f9[RDDpV'U2.,aNE2@f&.^):qp$*>k*,Tj]*g*^$NuN5J4>kMo'S(9flD
	oT+\f.NNG$DI>@>Wd0KmLF=O']%4SJ^&)POo")1sNque,A*>.N\bFS!g3MVc2(SJ]",'luKY8"5:em
	..imBg=)?^ds)t(Q1=C5mK0=M/n<Tc9KjdS[@;57Rt&;18@(H&?:cp7g>`2#k*`#kRP.jn""5o1Ce9
	H91`t3?Z#1>MVD#tb;q'[oEKm:.Ph&^286TPO/<#'1A&GtmMbQW4_5VQV.O%7EEf]B,&3im7@7irq+
	t*tAOfH[-4q9#?##?:,OKa5ro!'lIk/P&u4(O\UFh'o$+_W5k*>BFA_F/0V:JET2O8;t[p*<=:bD[L
	Kin@n*WBCP$a(r@qSFg6A.Wt]\5L\f8/58"Z$-:_I-0=53-*"&^CNOW5:%.@uZ,:5.gM[ME^Ldf6$B
	u+WYE`3n1;2eH't9qT)*l;LNtn2Vl2Gr+ngs^`aFnd>/%_F'8GVjmYNSP9nr\Qe=>&Qoc)d/;WKt^R
	3b>dUD?022.t!CBX\u1+\Og/!cfaUed=S+OhIa+I"I9qr@G;1o-)b'U+.uc^[8o["W[#.DD7b8+gSs
	6!j2o#(',=DS<:><VS%6)E]*3^1nH:rt`J!ILf>B9jU%K;.n@*2"k9CLGrGk>l4:Hjf;Eg\XZU!N!q
	u/,>908TmC:2sfiH+3JaE6f0FDA&OlT`.V+!.&;=6"$CCHR.mUiM%`FY8it'DOmdSpq9hTcDgnF1_J
	Q!!#SZ:.26O@"J
	ASCII85End
End


// PNG: width= 120, height= 40
Picture PicBackShi
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!"D!!!!I#Qau+!4mucEW?(>&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U!d@4(5u_NKm@1A@_CuCQ6WJu*_%It;,8(sA_`K"2%_Nei!ulRl7^a7VB;-YGS]7p=\8Ou4gVj-\R
	O3_Wf6,(6!-Z!1om/KCG[5\E/[bYpe.ICZjj3XF@>=ma[E"Nq6JZ,P)C(u^0rF9J_r20p\%Pi]JA&7
	R>F-]&BE0Fuo_j4L0<"*>,Rln9P^'Rd--=-oYqXF7Z_8IHIZH.KbKK!VgN2nPL$%oM:lb-:3I9&Uf*
	g@(*g`C'84JTY3:T;2Y\uskjiRBT7"cYLfKGO5UsOumiLtK!,baCg5uWE)dEt&h0]6G'*Yu=?<3]Y0
	b@=jL)4f-]C;B*U1QiAsE&&arHg^cE?:iuHIA"4?2(53q9J;`W7VA^E*\d:O`tHdT^[U^OmcfXt4gT
	/lSr4J)U!qOG*IhM5'CiR^]f"LI-b`GDb6(f;=H)T8-/g,d8fd;C((sj.6GjnT)'5pQYVk=G,ii$?H
	uVZU"5s97R5JQ:\VQK1Zteq.lZt*O7ZDSDX;%nCa--?-D6q?RF*i8Heb:JW!Z(:82XcS7mpC"Zi%(X
	D?We':R#@\?=c?ObGV$u6W?_.2G8:kJcS<(3^Vp'a+]>*"--r,VKQfI3jr&GL6G$F'Cs1;Zh6cRfRY
	,I1O[k*2:Ch72+JI@GaP:m"Tm]+s>h>^g[bYi+XmWG>X\AhaE<*fMI)\lLO6%OehXPVISSU[GA)3qu
	N7>_I9kRH$g[LgrC@kr<lkU$ub[^;a^$nLqhsZE:4X@=>YE-`!E@OE`I)0/?I%cNSq"nVl-l&M3a1'
	f_nU`&TK`7kR5BP*>>6>A?[f?C.!(fUS7'8jaJc
	ASCII85End
End







// PNG: width= 121, height= 39
Picture PicBackLine
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!"D!!!!I#Qau+!4mucEW?(>&TgHDFAm*iFE_/6AH5;7DfQssEc39jTBQ
	=U!glPI5u_NKjdJE>Z7m!3,K#J:`LX9@E\*cdEucmL4ZL>#fS9j?`QFdhdd@kG^ADAiOG*K9ID6+(P
	FQ]W&-@cuD2eVtm.^D3m:PSOWq`'JGQ\#$a-=Z.^H:J0D$g8^[jb.-HH$"#7`8kJ9\["rj0AKpXduE
	l[Ua0_/k+4A!&17s:".U7m1lReYp<nn<4"X>*UI$tb9chr'.8@.C%D6o7BtN^im42[`g=jp*p7+)=0
	MH';EQ"]R.IskAiKSZHJu,<`ptD!dAW7D<`R@GT!XD!,!6L[1R9E;BLUE`gH;3hr^:19,IU,:N`go5
	^*_lIUJiIq9p]$$e+.;Hd+fFDm?.aHD8q7A9c[NC_\Q&T<m4[)dehhM/CT#`]l%,N)1T*BVGD7MWf8
	1(N+M3[F]cmC?&$o<>?^ordITT$;\(MLP'1jP"`%\nc,_q,7Q.ebXc-C#^L9F]_NIkRjs0SSA[IeD`
	1WAM#AKZ"6aA*5X;PVDcCiQPXUiKb(!MoI(njr"i,;oSKS&BQ0aT'f)B?C'H=`9G<m6qlfN#sg=)qm
	4]/UJYUmNkY"A`.T[DDfj2ftMM1Zj>V;3l?8]A:n]*E+CW`oOcM4Z$-uZ!LpSPF@e8WI2^bPcN?W*d
	O(dgu%Y9)9!W8nJci=:A0stSRJHT'F?4\cR25nBXamb\(fm39JVp-@,4-C/nG$%3h>bA^5REBNGcc,
	oPFGhj7OsN_m)p`_N7VDQET/]$R>=H#QUm)b'8th$M0ZKriJ4`2p#mX<E40k'$FD5nV,_L\ur6gCZN
	*_Of[1#oD*3SmmOcH*OP=$SBBS+br;fC-!MT(LBDhAF0O<&QqpYpRifE*&<k6\DgMHa!!#SZ:.26O@
	"J
	ASCII85End
End

