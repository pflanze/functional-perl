use experimental "signatures";

+{
    logfile => "logwatch_example.log",
    match   => sub($line) {
        $line =~ /yes/
    },
    collecttime => 4,
    report      => sub($path) {
        print " == REPORT: ======= \n";
        system "cat", $path;
        print "================== \n";
        unlink $path;
    },
    }
