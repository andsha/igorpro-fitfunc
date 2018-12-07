#pragma rtGlobals=1		// Use modern global access method.

Menu "XPS" 
	XPSFitMenuText(), LoadXPSFit()
	"Update...", UpdateXPSFit()
end

variable /g hhh = 10

function UpdateXPSFit()
	NewPanel /W = (500,100,600,150) /N = XPS_Fit_Update
	Button Download pos = {1,1}, size = {98,48}, title="Step1: Unload", proc = UnloadXPSFit
end


function UpdateXPSFitf(ctrlname)	
	string ctrlname
	
	CreateXPSFitUpdateGlobals()
	svar url = g_url
	svar username = g_username
	svar password = g_password
	svar procstoload = g_procstoload 
	svar savepath = g_savepath
	variable idx = 0	
	string executestr = ""
	string procname= ""
	string savefile = ""
	string str = ""
	string response = ""
	print "Connect to server"
	for (idx = 0; idx < itemsinlist(procstoload); idx += 1)

		procname = stringfromlist(idx,procstoload)
		print "downloading ", procname
		str = "http://" + username + ":" + password + "@" + url + procname
		response = FetchURL(str)
		//print strlen(response)
		variable error = GetRTError(1)
		if (error != 0) // error
			Print "error in",  procname , ": ", GetErrMessage (error)
			DoWindow /K XPS_Fit_Update
			KillDataFOlder /Z ("root:XPSFit_update")
			abort
		else // no error
			
			savefile = savepath + procname
			variable refNum
			Close /A
			newpath /O path savepath
			DeleteFile /Z/P=path procname
			variable p = 0
			Open /Z/A/P=path refNum as procname
			if (v_flag != 0) // error
				print "error in", procname, ": ", GetErrMessage (v_flag)
				DoWindow /K XPS_Fit_Update
				KillDataFOlder /Z ("root:XPSFit_update")
				abort
			endif
			FBinWrite refNum, response
			Close refNum
			print "loaded ", procname, strlen(response), "bytes"
		endif	
	
	endfor

	for (idx = 0; idx < itemsinlist(procstoload); idx += 1)
		procname = stringfromlist(idx,procstoload)
		if (cmpstr(procname[strlen(procname) - 4, strlen(procname)], ".ipf") == 0 && cmpstr(procname ,"xpsfit_updater.ipf") != 0)
			//print procname[strlen(procname) - 4, strlen(procname)]
			executestr = "INSERTINCLUDE " + "\""  + procname[0, strlen(procname) - 5] + "\""
		endif
		//print executestr
		//print executestr
		Execute /P/Q/Z executestr
	endfor
	Execute/P/Q/Z "COMPILEPROCEDURES "
	DoWindow /K XPS_Fit_Update
	KillDataFOlder /Z ("root:XPSFit_update")

	If (!strlen(WinList("Quick_File_Viewer",";","")))
		DoWindow /K Quick_File_Viewer
	endif
	
	
	If (!strlen(WinList("XPS_Fit_Panel",";","")))
		DoWindow /K XPS_Fit_Panel
	endif
	
end
 
 
 function unloadXPSFit(ctrlname)
 	string ctrlname

	CreateXPSFitUpdateGlobals()
	svar procstoload = g_procstoload 
	variable idx = 0	
	svar procstoload = g_procstoload
	string executestr = ""
	string procname= ""
	
	for (idx = 0; idx < itemsinlist(procstoload); idx += 1)
		procname = stringfromlist(idx,procstoload)
		executestr =  "DELETEINCLUDE " + "\""  + procname[0, strlen(procname) - 5] + "\""
		//print executestr
		Execute /P/Q/Z executestr		
	endfor
	
	SVAR /Z XPSWindowName = root:XPS_Fit_dialog:XPSWindowName
	if (svar_exists(XPSWindowName))
		if (wintype(XPSWindowName) != 0) 
			KillWindow $XPSWindowName
		endif
	endif
	
	if(wintype("Quick_File_Viewer") != 0)
		KillWindow Quick_File_Viewer	
	endif
	
	Execute/P/Q/Z "COMPILEPROCEDURES "
	DoWindow /K XPS_Fit_Update
	NewPanel /W = (500,100,600,150) /N = XPS_Fit_Update
	Button Download pos = {1,1}, size = {98,48}, title="Step2: Update", proc = UpdateXPSFitf
end

function LoadXPSFit()
	
	CreateXPSFitUpdateGlobals()
	variable idx = 0	
	svar procstoload = g_procstoload 
	svar savepath = g_savepath
	string executestr = ""
	string procname= ""
	
	for (idx = 0; idx < itemsinlist(procstoload); idx += 1)
		procname = stringfromlist(idx,procstoload)	
		variable refnum
		newpath/O path savepath
		open /R/Z /P=path refnum as procname
		if (v_flag == -43)
			//KillDataFolder /Z ("root:XPSFit_update")
			print v_flag, GetErrMessage(v_flag)
			abort (procname + " procedure is not loaded. Use update")
		else
			if (cmpstr(procname[strlen(procname) - 4, strlen(procname)], ".ipf") == 0  && cmpstr(procname ,"xpsfit_updater.ipf") != 0)
				executestr = "INSERTINCLUDE " + "\""  + procname[0, strlen(procname) - 5] + "\""
			endif
			Execute /P/Q/Z executestr
		endif
		close refnum
	endfor
	Execute/P/Q/Z "COMPILEPROCEDURES "
	nvar /Z b = g_menuload
	b = 0
	KillDataFOlder /Z ("root:XPSFit_update")
	buildMenu "XPS"
	
end

function CreateXPSFitUpdateGlobals()
	
	NewDataFolder /O $("root:XPSFit_update")
	SetDataFolder $("root:XPSFit_update")
	string /G g_procstoload = "XPSFit_updater.ipf;XPS_NEW_fit_dialog.ipf;XPS_quick_file_viewer.ipf;ntable.txt"
	string /G g_url = "beamline1102.als.lbl.gov/data/APPES2/IgorProcedures/"
	string /G g_username = "bl1102"
	string /G g_password = "11als02"
	string /G g_savepath = ":User Procedures:"
end

function /S XPSFitMenuText()
	//print "start"
	CreateXPSFitUpdateGlobals()
	svar procstoload = g_procstoload
	variable idx = 0
	string str = ""
	
	for (idx = 0; idx < itemsinlist(procstoload); idx += 1)
		str += FunctionList((stringfromlist(idx,procstoload))[0,strlen(stringfromlist(idx,procstoload))-5],";","")
	endfor
		//print "str=",str
		if (!strlen(str))
				//print "noting"
				KillDataFOlder /Z ("root:XPSFit_update")
				return "Load XPS menu"
			else
				//print str
				KillDataFOlder /Z ("root:XPSFit_update")
				return ""
			endif
		

end




function ftest()


	 variable idx = 0	
	string procstoload = "XPS_NEW_fit_dialog.ipf;XPS_quick_file_viewer.ipf;"
	string executestr = ""
	string procname= ""
		
	for (idx = 0; idx < itemsinlist(procstoload); idx += 1)
		procname = stringfromlist(idx,procstoload)
		executestr =  "DELETEINCLUDE " + "\""   + procname[0, strlen(procname) - 5] + "\""
		//print executestr
		Execute /P/Q/Z executestr
		
	endfor
	Execute/P/Q/Z "COMPILEPROCEDURES "
end

function ttest()
	variable refnum
	newpath/O file ":User Procedures:"
	print IndexedFile(file, -1,"????")
	open /P = file refnum as "aa.txt"
end
