%% This is the application resource file (.app file) for the 'base'
%% application.
{application, appl_mgr,
[{description, "Appl_Mgr application and cluster" },
{vsn, "0.1.0" },
{modules, 
	  [appl_mgr_app,appl_mgr,appl_mgr_sup,appl_mgr_server,lib_appl_mgr]},
{registered,[appl_mgr]},
{applications, [kernel,stdlib]},
{mod, {appl_mgr_app,[]}},
{start_phases, []},
{git_path,"https://github.com/joq62/appl_mgr.git"},
{constraints,[]}
]}.
