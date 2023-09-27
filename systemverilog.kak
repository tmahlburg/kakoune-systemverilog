# Verilog for Kakoune

# Detection
hook global WinCreate .*\.(sv|svh) %{
    set-option window filetype systemverilog
}

# Set up comments
hook global WinSetOption filetype=verilog %{
	set-option window comment_block_begin /*
	set-option window comment_block_end */
	set-option window comment_line //
}

# Highlighting
add-highlighter shared/verilog regions
add-highlighter shared/verilog/code default-region group
add-highlighter shared/verilog/string region '"' (?<!\\)(\\\\)*" fill string
add-highlighter shared/verilog/comment_line region '//' $ fill comment
add-highlighter shared/verilog/comment region /\* \*/ fill comment

evaluate-commands %sh{
    keywords='@ assign automatic break cell constraint continue deassign default defparam design disable dist edge fork final genvar ifnone incdir import inside instance join join_any join_none liblist library localparam mailbox modport negedge noshowcancelled parameter posedge primitive priority pulsestyle_ondetect pulsestyle_oneventi rand randc release return scalared semaphore showcancelled solve specparam strength table tri tri0 tri1 triand trior unique use vectored wait'
    blocks='always always_comb always_latch always_ff case casex casez class endclass else endcase for foreach forever function endfunction if repeat while do begin config end endconfig endfunction endgenerate endmodule endprimitive endspecify endtable endtask fork function generate initial join macromodule module specify task clocking endclocking program endprogram package endpackage interface endinterface'
    declarations='bit byte chandle enum event inout input int integer logic longint output real realtime reg shortint signed string struct time trireg typedef union unsigned uwire virtual void wand wor wire'
    gates='and or xor nand nor xnor buf not bufif0 notif0 bufif1 notif1 pullup pulldown pmos nmos cmos tran tranif1 tranif0'
    symbols='+ - = == != !== === ; <= ( ) += -= *= /= %= &= ^= |= <<= >>= <<<= >>>= ++ -- ==? !=? [ ] { } -> ->>'
    system_tasks='display write strobe monitor monitoron monitoroff displayb writeb strobeb monitorb displayo writeo strobeo monitoro displayh writeh strobeh monitorh fopen fclose frewind fflush fseek ftell fdisplay fwrite swrite fstrobe fmonitor fread fscanf fdisplayb fwriteb swriteb fstrobeb fmonitorb fdisplayo fwriteo swriteo fstrobeo fmonitoro fdisplayh fwriteh swriteh fstrobeh fmonitorh sscanf sdf_annotate srandom urandom urandom_range root bits left right low high increment size dimensions unpacked_dimensions'

    join() { sep=$2; eval set -- $1; IFS="$sep"; echo "$*"; }

    # Add the language's grammar to the static completion list
    printf %s\\n "hook global WinSetOption 'filetype=verilog' %{ set-option window static_words $(join "${keywords} ${blocks} ${declarations} ${gates} ${symbols} ${system_tasks}" ' ') }"

	# Highlight keywords
    printf %s "
        add-highlighter shared/verilog/code/ regex \b($(join "${keywords}" '|'))\b 0:keyword
        add-highlighter shared/verilog/code/ regex \b($(join "${blocks}" '|'))\b 0:attribute
        add-highlighter shared/verilog/code/ regex \b($(join "${declarations}" '|'))\b 0:type
        add-highlighter shared/verilog/code/ regex \b($(join "${gates}" '|'))\b 0:builtin
        add-highlighter shared/verilog/code/ regex \b($(join "${symbols}" '|'))\b 0:operator
    "
}

add-highlighter shared/verilog/code/ regex '\$\w+' 0:function
add-highlighter shared/verilog/code/ regex '`\w+' 0:meta
add-highlighter shared/verilog/code/ regex "\d+'[bodhBODH][1234567890abcdefABCDEF]+" 0:value
add-highlighter shared/verilog/code/ regex "(?<=[^a-zA-Z_])\d+" 0:value

# Indentation

define-command -hidden verilog-indent-on-new-line %{
    evaluate-commands -no-hooks -draft -itersel %{
        # preserve previous line indent
        try %{ execute-keys -draft K <a-&> }
        # indent after start structure
        try %{ execute-keys -draft k <a-x> <a-k> ^ \h * (always|case|casex|casez|class|else|for|forever|function|if|repeat|while|begin|config|fork|function|generate|initial|join|macromodule|module|specify|task)\b|(do\h*$|(.*\h+do(\h+\|[^\n]*\|)?\h*$)) <ret> j <a-gt> }
        try %{
          # previous line is empty, next is not
          execute-keys -draft k <a-x> 2X <a-k> \A\n\n[^\n]+\n\z <ret>
          # copy indent of next line
          execute-keys -draft j <a-x> s ^\h+ <ret> y k P
        }
    }
}

# Initialization

hook global WinSetOption filetype=verilog %{
	hook window InsertChar \n -group verilog-indent verilog-indent-on-new-line
	add-highlighter window/verilog ref verilog
	hook -once -always window WinSetOption filetype=(?!verilog).* %{
    	remove-hooks window verilog-indent
    	remove-highlighter window/c
    }
}
