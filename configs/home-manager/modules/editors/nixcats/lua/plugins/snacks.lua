return {
	{
		"folke/snacks.nvim",
		enabled = true,
		event = "VeryLazy",

		opts = {
			animate = { enabled = true },

			dashboard = {
				enabled = true,
				preset = {
					-- header = [[
					--                    @99o..                                        
					--                    `99   o                                       
					--                     99.aad9.                                     
					--              "bad9999999999P                                     
					--                     99                                           
					--                   od99o.                                         
					--                  99 99 9o        .o                              
					--                  `9999999     ,// `a                             
					--                .ooP`99P'   .o%    ,@9.                           
					--             .''       .oaadObooooa9999                           
					--         . ~  .oad999999999999999P'                                
					--        "soo999999999999999P"'                                    
					--             ,.oaa99aooo.                                         
					--           .  ,o9999999999.   o@@o                                
					--           o o99'        `99   @@@                                
					--           `99'       ,oda9'   "'                                 
					--                     0   a999o.                                   
					--                     `.ao" `999,                                  
					--                            `999;          A Chinese character    
					--                             999           (means long life).     
					--               o            ,99'                                  
					--                `9a,       ,9F             Z. LIN  17 MARCH, 1994 
					--                  "*bo. ,g9"                                      
					--    ]],
          header = [[


⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣾⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠛⣛⡛⠹⣿⡅⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⣿⣿⣿⣿⣷⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣤⣌⣙⣉⣥⣬⣭⣉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⠄⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⣿⠏⠀⠀⠀⠀⢻⣿⣿⣿⣿⣿⣿⡟⠀⢀⣠⣤⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣤⣤⣤⣤⣤⣾⣿⣿⠋⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣿⣿⠀⢰⣿⣿⣿⣿⣿⣷⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⢠⣶⣶⣶⣤⣴⣶⣿⣿⣿⣿⣿⡟⣋⣭⣥⣤⣴⣶⣿⣷⡆⠀⠀⢸⣿⣿⣿⣿⣿⠀⣿⣿⢛⣉⣉⣉⣩⣤⣶⣶⣤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠻⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢰⣿⣿⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⣿⣿⣿⣿⣿⠀⣿⣇⢸⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣰⣶⣶⣦⡈⢻⣿⣿⣿⣿⣿⣿⡿⠛⠘⣿⣿⣿⣿⣿⣿⡿⠋⣠⣶⠀⠀⣿⣿⣿⣿⣿⠀⢻⣿⡄⠻⣿⣿⣿⣿⣿⣿⡟⢀⣤⣴⣤⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣿⣿⣿⣿⣿⣦⣙⠿⣿⠿⠛⠁⠀⠀⠀⣿⣿⣿⣿⣿⡿⠁⣼⣿⣿⠀⠀⣿⣿⣿⣿⣿⠀⠈⣿⣷⠀⠹⣿⣿⣿⣿⠀⠀⣾⡿⠛⣛⣛⣛⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠸⣿⣿⣿⣿⣿⣿⣿⣦⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⡇⠰⣿⣿⣿⠀⠀⣿⣿⣿⣿⣿⠀⠰⠿⠟⠀⠀⢿⣿⣿⣿⡆⢠⡟⣠⣾⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀
⠀⢻⣿⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⡇⠀⠻⣿⣿⠀⠀⣿⣿⣿⣿⣿⡀⠀⣴⣿⡆⠀⠸⣿⣿⣿⣿⠀⢰⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⢿⣿⣿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⡇⢠⡀⢿⡿⠀⠀⢸⣿⣿⣿⣿⡇⠀⢿⣿⣧⠀⠀⢿⣿⣿⣿⣇⢸⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠘⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣿⠀⣸⣿⣶⣦⠀⠀⢸⣿⣿⣿⣿⡇⠀⠀⠻⢿⣦⡀⢸⣿⣿⣿⣿⡄⢻⣧⠙⢿⣿⣿⣷⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⢹⣿⣿⡇⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⡟⠀⣿⣿⠟⠁⠀⠀⢸⣿⣿⣿⣿⣷⡀⠀⠀⠀⠈⠀⢸⣿⣿⣿⣿⣷⡀⢻⠀⠀⢻⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⢸⣿⣿⡇⠀⠀⠀⠀⠀⣠⣿⣿⣿⣿⣿⣿⣷⡀⠛⠁⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⣶⣄⠀⢀⣴⣿⣿⣿⣿⣿⣿⣷⡀⠀⠀⠀⣿⣿⣿⣿⣶⣄⡀⠀⠀⠀
⠀⠀⠀⠈⣿⣿⡇⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣆⠀⠀⢀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⠀⣼⣿⣿⣿⣿⣿⣿⣿⣆⠀⠀
⠀⠀⠀⠀⣿⣿⣇⠀⠀⠀⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⣾⣿⣿⣿⣿⠿⢿⣿⣿⣿⠟⠁⠘⣿⣿⣿⣿⡿⠿⢿⣿⣿⣿⣿⡇⢹⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀
⠀⠀⠀⢀⣿⣿⣿⣄⠀⠀⠘⢿⣿⣿⣿⠟⢋⣉⣭⣭⣍⣁⡀⠀⠘⠿⠟⣩⣴⣶⣶⣮⣍⣥⣶⣶⡄⠻⠟⣋⣥⣶⣶⣦⣝⠛⣛⡛⠃⢸⡿⠟⣋⣉⣛⠻⠏⠙⠇⠀
⠀⠀⢠⣿⣿⣿⣿⣿⣷⣄⠀⠀⢀⣤⣤⣴⣿⣿⣿⣿⣿⣿⣿⣿⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⠀⢠⣶⣿⣿⣿⣿⣷⣀⣿⣆⠀
⠀⢀⣿⣿⠿⠻⠿⢿⣿⣿⠇⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆
⠀⠈⣿⢇⣶⣿⣷⣶⣦⣄⡀⠀⠙⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⡘⢿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⠁⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷
⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠈⠻⣿⣿⣿⣿⣿⣿⣿⣿⠇⠈⣿⣿⣿⣿⣿⣿⣿⡏⠀⠀⠀⢰⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⠁⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⠏
⠀⠀⢹⣿⣿⣿⣿⣿⣿⣿⣷⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⠋⠀⠀⠘⣿⣿⣿⣿⣿⣿⠇⠀⠀⢠⣿⣿⣿⣿⣿⣿⡿⠋⠀⢀⣴⣾⣿⣿⣿⣿⣿⣿⣿⡿⠛⠁⠀
⠀⠀⠀⠙⢿⣿⣿⣿⣿⣿⣿⡀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⢸⣿⣿⣿⣿⡟⠀⠀⢠⣿⣿⣿⣿⣿⣿⠋⠀⠀⢀⣾⣿⣿⣿⣿⣿⡿⠛⠉⠁⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠈⠻⣿⣿⣿⣿⣿⣦⡀⠀⠀⠀⠸⣿⣿⣿⣿⣿⣆⠀⠀⠀⣼⣿⣿⣿⡿⠀⠀⣰⣿⣿⣿⣿⣿⠟⠁⠀⠀⣠⣿⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠹⣿⣿⣿⣿⣿⣿⣦⡀⠀⠀⢻⣿⣿⣿⣿⣿⣧⠀⢠⣿⣿⣿⣿⡇⢠⣾⣿⣿⣿⣿⣿⠋⠀⠀⣀⣴⣿⣿⣿⣿⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣿⣿⣿⣿⣿⣿⣷⣄⠸⣿⣿⣿⣿⣿⣿⣴⣿⣿⣿⣿⣿⡇⢸⣿⣿⣿⣿⣿⠃⣾⣿⣿⣿⣿⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣿⣿⣿⣿⣿⣿⣿⠀⣿⣿⣿⣿⣿⣿⢿⣿⣿⣿⣿⣿⡿⢸⣿⣿⣿⣿⣿⢰⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣿⣿⡿⢋⣉⣍⡀⠙⠿⣿⣿⣿⠟⢠⣿⣿⣤⣉⣭⡄⣾⣿⣿⣿⣿⣿⠈⠻⠿⠿⠛⠉⢿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⡇⢸⣿⣿⣧⢰⣷⣶⣤⣴⣆⣾⣿⣿⣿⣿⣿⣧⣿⣿⣿⣿⣿⠟⢰⣿⣶⣶⣿⠇⠈⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠻⠷⠘⢿⣿⣿⡀⢿⣿⣿⣿⡟⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⣠⣾⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠛⢿⣷⡌⢿⣿⣿⡇⣿⣿⣿⠏⣴⣶⣿⡿⠟⢁⣠⣾⣿⠿⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠁⠀⠉⠙⠁⠈⠛⠋⠀⠛⠛⠋⠠⣶⠿⠟⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
          ]],
				},
				sections = {
					{ section = "header" },
					{
						padding = 2,
						align = "center",
						text = {
							{ "Neovim :: Welcome back pɹɐʍpǝ", hl = "Title" },
						},
					},
				},
			},

			explorer = { enabled = false },
			bigfile = { enabled = true },

			input = {
				enabled = true,
				backdrop = false,
				position = "float",
				border = true,
				title_pos = "center",
			},

			image = {
				enabled = true,
				resolve = function(file, src)
					local clean_src = src:match("^(.-)\\") or src

					local image_dirs = {
						vim.fn.expand("~/Documents/notes/999 Images"),
						vim.fn.expand("/mnt/Storage/Documents/notes/999 Images/"),
					}

					for _, dir in ipairs(image_dirs) do
						local full_path = vim.fn.fnamemodify(dir .. "/" .. clean_src, ":p")
						if vim.fn.filereadable(full_path) == 1 then
							return full_path
						end
					end

					local fallback_path = vim.fn.fnamemodify(file:match("(.*/)") .. clean_src, ":p")
					return fallback_path
				end,

				doc = {
					enable = true,
					inline = true,
					float = false,
					max_width = 80,
					max_height = 40,
				},

				math = {
					enabled = true,

					typst = {
						tpl = [[
        #set page(width: auto, height: auto, margin: (x: 2pt, y: 2pt))
        #show math.equation.where(block: false): set text(top-edge: "bounds", bottom-edge: "bounds")
        #set text(size: 12pt, fill: rgb("${color}"))
        ${header}
        ${content}
        ]],
					},

					latex = {
						font_size = "small",
						packages = { "amsmath", "amssymb", "amsfonts", "amscd", "mathtools" },
						tpl = [[
        \documentclass[preview,border=0pt,varwidth,12pt]{standalone}
        \usepackage{${packages}}
        \begin{document}
        ${header}
        { \${font_size} \selectfont
          \color[HTML]{${color}}
        ${content}}
        \end{document}
        ]],
					},
				},
			},

			indent = {
				enabled = true,
				priority = 1,
				char = "|",
				animate = { enabled = true },
			},

			notifier = { enabled = true },
			scope = { enabled = true },
			scroll = { enabled = false },
			words = { enabled = true },
			toggle = { enabled = true },

			styles = {
				input = {
					position = "float",
					backdrop = false,
					border = true,
					title_pos = "center",
				},
			},
		},

		config = function(_, opts)
			local Snacks = require("snacks")
			Snacks.setup(opts)
		end,

		keys = {
			{
				"<leader>n",
				function()
					require("snacks").picker.notifications()
				end,
				desc = "Notifications",
			},
			{
				"<C-\\>",
				function()
					require("snacks").terminal.open()
				end,
				desc = "Snacks Terminal",
			},
			{
				"<leader>_",
				function()
					require("snacks").lazygit.open()
				end,
				desc = "Snacks LazyGit",
			},

			{
				"<leader>sf",
				function()
					require("snacks").picker.smart()
				end,
				desc = "Smart Find Files",
			},
			{
				"<leader><leader>s",
				function()
					require("snacks").picker.buffers()
				end,
				desc = "Search Buffers",
			},
			{
				"<leader>ff",
				function()
					require("snacks").picker.files()
				end,
				desc = "Find Files",
			},
			{
				"<leader>fg",
				function()
					require("snacks").picker.git_files()
				end,
				desc = "Find Git Files",
			},

			{
				"<leader>sb",
				function()
					require("snacks").picker.lines()
				end,
				desc = "Buffer Lines",
			},
			{
				"<leader>sB",
				function()
					require("snacks").picker.grep_buffers()
				end,
				desc = "Grep Open Buffers",
			},
			{
				"<leader>sg",
				function()
					require("snacks").picker.grep()
				end,
				desc = "Grep",
			},
			{
				"<leader>sw",
				function()
					require("snacks").picker.grep_word()
				end,
				mode = { "n", "x" },
				desc = "Grep Word/Visual",
			},

			{
				"<leader>sd",
				function()
					require("snacks").picker.diagnostics()
				end,
				desc = "Diagnostics",
			},
			{
				"<leader>sD",
				function()
					require("snacks").picker.diagnostics_buffer()
				end,
				desc = "Buffer Diagnostics",
			},

			{
				"<leader>sh",
				function()
					require("snacks").picker.help()
				end,
				desc = "Help Pages",
			},
			{
				"<leader>sl",
				function()
					require("snacks").picker.loclist()
				end,
				desc = "Location List",
			},
			{
				"<leader>sm",
				function()
					require("snacks").picker.marks()
				end,
				desc = "Marks",
			},
			{
				"<leader>sM",
				function()
					require("snacks").picker.man()
				end,
				desc = "Man Pages",
			},
			{
				"<leader>sq",
				function()
					require("snacks").picker.qflist()
				end,
				desc = "Quickfix List",
			},
			{
				"<leader>sR",
				function()
					require("snacks").picker.resume()
				end,
				desc = "Resume",
			},
			{
				"<leader>su",
				function()
					require("snacks").picker.undo()
				end,
				desc = "Undo History",
			},
		},
	},
}
