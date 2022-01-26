%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(lib_appl_mgr).   
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
%-include("log.hrl").
-include("appl_mgr.hrl").
%%---------------------------------------------------------------------
%% Records for test
%%
%-define(ScheduleInterval,20*1000).
%-define(ConfigsGitPath,"https://github.com/joq62/configs.git").
%-define(ConfigsDir,filename:join(?ApplMgrConfigDir,"configs")).
%-define(ApplicationsDir,filename:join(?ConfigsDir,"applications")).
%-define(ApplMgrConfigDir,"appl_mgr.dir").

%% --------------------------------------------------------------------
%-compile(export_all).

-export([
	 git_load_configs/0,
	 load_app_specs/0,
	 update_app_specs/1,
	 get_app_dir/3,
	 exists/2,
	 exists/3
	]).


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
git_load_configs()->
    os:cmd("rm -rf "++?ApplMgrConfigDir),
    ok=file:make_dir(?ApplMgrConfigDir),
    ok=file:make_dir(?ConfigsDir),
    os:cmd("git clone "++?ConfigsGitPath++" "++?ConfigsDir),
    Result=case filelib:is_dir(?ApplicationsDir) of
	       false->
		   {error,[failed_create,?ApplMgrConfigDir,?ApplicationsDir]};
	       true->
		   ok
	   end,
    Result.   
    

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

load_app_specs()->
    Result=case get_appfiles() of
	       {error,Reason}->
		   {error,Reason};
	       {ok,AppFiles}->
		   AppInfo=git_load_app_specs(AppFiles),
		   {ok,AppInfo}
	   end,
    Result.

update_app_specs(AppInfoList)->
    Result=case get_appfiles() of
	       {error,Reason}->
		   {error,Reason};
	       {ok,AppFiles}->
		   AppInfo=git_update_app_specs(AppFiles),
		   case git_update_app_specs(AppFiles) of
		       []->
			   {ok,AppInfoList};
		       Updates->
			   %ToDo		
			   {ok,AppInfoList}
		   end
	   end,
    Result.
		   
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
get_app_dir(App,latest,AppInfo)->
    AppList=[{XApp,XVsn,AppDir}||{XApp,XVsn,AppDir}<-AppInfo,
			App=:=XApp],
    SortedAppList=lists:reverse(lists:keysort(2,AppList)),
    Result=case SortedAppList of
	       []->
		   {error,[eexists,App,latest]};
	       [{_App,_Vsn,LatestDir}|_]->
		   {ok,LatestDir}
	   end,
    Result;

get_app_dir(App,Vsn,AppInfo)->
    AppDirList=[AppDir||{XApp,XVsn,AppDir}<-AppInfo,
			{App,Vsn}=:={XApp,XVsn}],
    Result=case AppDirList of
	       []->
		   {error,[eexists,App,Vsn]};
	       [Dir]->
		   {ok,Dir}
	   end,
    Result.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
exists(App,AppInfo)->
    lists:keymember(App,1,AppInfo).
 
exists(App,Vsn,AppInfo)->
    Result=case get_app_dir(App,Vsn,AppInfo) of
	       {error,_}->
		   false;
	       _ -> 
		   true
	   end,
    Result.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
%% -------------------------------------------------------------------
get_appfiles()->
    Result=case filelib:is_dir(?ApplicationsDir) of
	       false->
		   {error,[eexists,?ApplicationsDir]};
	       true->
		   {ok,AllFiles}=file:list_dir(?ApplicationsDir),
		   AppFiles=[{File,filename:join(?ApplicationsDir,File)}||File<-AllFiles,
									  ".app"=:=filename:extension(File)],
		   {ok,AppFiles}
	   end,
    Result.
	       

    
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
git_load_app_specs(AppFiles)->
    git_load_app_specs(AppFiles,[]).

git_load_app_specs([],LoadRes)->
    [{App,Vsn,AppDir}||{ok,App,Vsn,AppDir}<-LoadRes];
git_load_app_specs([{_File,FullPath}|T],Acc)->
    App=appfile:read(FullPath,application),
    Vsn=appfile:read(FullPath,vsn),
    GitPath=appfile:read(FullPath,git_path),
    AppTopDir=atom_to_list(App),
    AppDir=filename:join(AppTopDir,Vsn),
    NewAcc=case filelib:is_dir(AppTopDir) of
	       false->
		   ok=file:make_dir(AppTopDir),
		   ok=file:make_dir(AppDir),
		   os:cmd("git clone "++GitPath++" "++AppDir),
		   [{ok,App,Vsn,AppDir}|Acc];
	      true ->
		  case filelib:is_dir(AppDir) of
		      false->
			  ok=file:make_dir(AppDir),
			  os:cmd("git clone "++GitPath++" "++AppDir),
			  [{ok,App,Vsn,AppDir}|Acc];
		      true ->
			  os:cmd("rm -rf "++AppDir),
			  os:cmd("git clone "++GitPath++" "++AppDir),
			  [{ok,App,Vsn,AppDir}|Acc]
		  end
	   end,
  
    %% Check if it worked ?
    git_load_app_specs(T,NewAcc).
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
git_update_app_specs(AppFiles)->
    git_update_app_specs(AppFiles,[]).

git_update_app_specs([],LoadRes)->
    [{App,Vsn,AppDir}||{ok,App,Vsn,AppDir}<-LoadRes];
git_update_app_specs([{_File,FullPath}|T],Acc)->
    App=appfile:read(FullPath,application),
    Vsn=appfile:read(FullPath,vsn),
    GitPath=appfile:read(FullPath,git_path),
    AppTopDir=atom_to_list(App),
    AppDir=filename:join(AppTopDir,Vsn),
    NewAcc=case filelib:is_dir(AppTopDir) of
	       false->
		   ok=file:make_dir(AppTopDir),
		   ok=file:make_dir(AppDir),
		   os:cmd("git clone "++GitPath++" "++AppDir),
		   [{ok,App,Vsn,AppDir}|Acc];
	      true ->
		  case filelib:is_dir(AppDir) of
		      false->
			  ok=file:make_dir(AppDir),
			  os:cmd("git clone "++GitPath++" "++AppDir),
			  [{ok,App,Vsn,AppDir}|Acc];
		      true ->
			  Acc
		  end
	  end,
  
    %% Check if it worked ?
    git_update_app_specs(T,NewAcc).
