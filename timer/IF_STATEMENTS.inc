;=================================================================================================
;     * IF/endIF statements *
;=================================================================================================
#ifndef __IF_STATEMENTS__
#define __IF_STATEMENTS__
.macro initONE
	.set p@0_@1_0 = 0
	.set p@0_@1_1 = 0
	.set p@0_@1_2 = 0
	.set p@0_@1_3 = 0
	.set p@0_@1_4 = 0
	.set p@0_@1_5 = 0
	.set p@0_@1_6 = 0
	.set p@0_@1_7 = 0
	.set p@0_@1_8 = 0
	.set p@0_@1_9 = 0
.endm
.macro initTWO
	initONE @0,0
	initONE @0,1
	initONE @0,2
	initONE @0,3
	initONE @0,4
	initONE @0,5
	initONE @0,6
	initONE @0,7
	initONE @0,8
	initONE @0,9
.endm

.set cc = -1
initTWO    0

//---------------------------------------------------------
.macro start_branch
	.if cc == 100*@1 + 10*@2 + @3
		.set p@1_@2_@3 = 1	@0 m@1_@2_@3
	.endif
.endm
.macro _end
	.if p@0_@1_@2 && ok
		.set ok = 0
		.set p@0_@1_@2 = 0
		.set m@0_@1_@2 = PC
	.endif
.endm
//---------------------------------------------------------
.macro StartBranchONE
	start_branch @0, @1,@2,0
	start_branch @0, @1,@2,1
	start_branch @0, @1,@2,2
	start_branch @0, @1,@2,3
	start_branch @0, @1,@2,4
	start_branch @0, @1,@2,5
	start_branch @0, @1,@2,6
	start_branch @0, @1,@2,7
	start_branch @0, @1,@2,8
	start_branch @0, @1,@2,9
.endm
.macro StartBranchTWO
	StartBranchONE @0, @1,0
	StartBranchONE @0, @1,1
	StartBranchONE @0, @1,2
	StartBranchONE @0, @1,3
	StartBranchONE @0, @1,4
	StartBranchONE @0, @1,5
	StartBranchONE @0, @1,6
	StartBranchONE @0, @1,7
	StartBranchONE @0, @1,8
	StartBranchONE @0, @1,9
.endm
//---------------------------------------------------------
.macro endONE
	_end @0,@1,9
	_end @0,@1,8
	_end @0,@1,7
	_end @0,@1,6
	_end @0,@1,5
	_end @0,@1,4
	_end @0,@1,3
	_end @0,@1,2
	_end @0,@1,1
	_end @0,@1,0
.endm
.macro endTWO
	endONE @0,9
	endONE @0,8
	endONE @0,7
	endONE @0,6
	endONE @0,5
	endONE @0,4
	endONE @0,3
	endONE @0,2
	endONE @0,1
	endONE @0,0
.endm
//------------------------------------------Short IF-----------------------------------------------
.macro Condition
	.set cc = cc + 1
	.if  cc > 99
		rjmp Limit
	.endif
	StartBranchTWO @0, 0
.endm
.macro IF
	.if(@1 == '=')
				cpi @0,@2	 Condition brne		//if @0 == @2   then "выполнить следующие команды" 
	.endif
	.if(@1 == '!')
				cpi @0,@2	 Condition breq 	//if @0 != @2   then "выполнить следующие команды"  
	.endif
	.if(@1 == '<')	
				cpi @0,@2	 Condition brge		//if @0 <  @2   then "выполнить следующие команды" 
	.endif
	.if(@1 == '{')	
				cpi @0,@2+1	 Condition brge		//if @0 <= @2   then "выполнить следующие команды" 
	.endif
	.if(@1 == '>')				
				cpi @0,@2+1  Condition brlt		//if @0 >  @2   then "выполнить следующие команды" 
	.endif
	.if(@1 == '}')				
				cpi @0,@2    Condition brlt		//if @0 >= @2   then "выполнить следующие команды" 
	.endif
.endm
.macro IFr
	.if(@1 == '=')
				cp @0,@2	 Condition brne 	//if @0 == @2   then "выполнить следующие команды"  
	.endif
	.if(@1 == '!')
				cp @0,@2	 Condition breq 	//if @0 != @2   then "выполнить следующие команды"  
	.endif
	.if(@1 == '<')	
				cp @0,@2	 Condition brge		//if @0 <  @2   then "выполнить следующие команды" 
	.endif
	.if(@1 == '{')	
				cp @2,@0	 Condition brlt 	//if @0 <= @2   then "выполнить следующие команды" 
	.endif
	.if(@1 == '>')	
				cp @2,@0	 Condition brge 	//if @0 >  @2   then "выполнить следующие команды" 
	.endif
	.if(@1 == '}')	
				cp @0,@2	 Condition brlt 	//if @0 >= @2   then "выполнить следующие команды" 
	.endif
.endm
.macro IFF
	.if(@1 == '=')
				cpi @0,@2	 brne PC+2			//if @0 == @2   then "выполнить следующую команду" 
	.endif
	.if(@1 == '!')
				cpi @0,@2	 breq PC+2			//if @0 != @2   then "выполнить следующие команды"  
	.endif
	.if(@1 == '<')	
				cpi @0,@2	 brge PC+2			//if @0 <  @2   then "выполнить следующую команду" 
	.endif
	.if(@1 == '{')	
				cpi @0,@2+1	 brge PC+2			//if @0 <= @2   then "выполнить следующую команду" 
	.endif
	.if(@1 == '>')				
				cpi @0,@2+1  brlt PC+2			//if @0 >  @2   then "выполнить следующую команду" 
	.endif
	.if(@1 == '}')				
				cpi @0,@2    brlt PC+2			//if @0 >= @2   then "выполнить следующую команду" 
	.endif
.endm
.macro IFFr
	.if(@1 == '=')
				cp @0,@2	 brne PC+2			//if @0 == @2   then "выполнить следующую команду" 
	.endif
	.if(@1 == '!')
				cp @0,@2	 breq PC+2			//if @0 != @2   then "выполнить следующие команды"  
	.endif
	.if(@1 == '<')	
				cp @0,@2	 brge PC+2			//if @0 <  @2   then "выполнить следующую команду" 
	.endif
	.if(@1 == '{')	
				cp @2,@0	 brlt PC+2			//if @0 <= @2   then "выполнить следующую команду" 
	.endif
	.if(@1 == '>')	
				cp @2,@0	 brge PC+2			//if @0 >  @2   then "выполнить следующую команду" 
	.endif
	.if(@1 == '}')	
				cp @0,@2	 brlt PC+2			//if @0 >= @2   then "выполнить следующую команду" 
	.endif
.endm
.macro endIF
	.set ok = 1
	endTWO 0
.endm
//------------------------------------------------------------------------------------------------
.macro set_bit
	.if @1 == 0
		andi @2,~(1<<@0)
	.else
		ori  @2, (1<<@0)
	.endif
.endm
.macro get_bit
	mov    @0, @2
	andi   @0, (1<<@1)
.endm
//------------------------------------------------------------------------------------------------
#endif
