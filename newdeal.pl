use strict;

use IO::Socket;
use Curses::UI;

my $server = "localhost";
my $nick = "newdeal";
my $login = "newdeal";
my $channel = "#newdeal";
my $color = 2;

my $cui = new Curses::UI( -color_support => 1);

#I don't want a traditional file, edit, exit kind of setup 
#the final product should be more like in Android where there's a context
#menu when you activate it, but we just want to learn some ncurses here
my @menu = (
    { -label => 'File', 
        -submenu => [
            { -label => 'Exit      ^Q', -value => \&exit_dialog  }
                    ]
    },
);

sub exit_dialog() {
    my $return = $cui->dialog(
        -message    => "Really quit?",
        -title      => "r u srs?",
        -buttons    => ['yes', 'no'],
    );
    
    exit(0) if $return;
}

my $menu = $cui->add(
    'menu', 'Menubar',
    -menu => \@menu,
    -fg   => "blue",
);

my $win1 = $cui->add(
    'win1', 'Window',
    -border => 1,
    -y      => 1,
    -bfg    => 'red',
);

my $ircwindow = $win1->add("irctext", "TextEditor",
    -text => "Curses initialized!\n");
    
$ircwindow->focus();
    
#my $ircwindow = $win1->add("inputbar", "TextEntry");
# my $text = $win1->get();

my $sock = new IO::Socket::INET (
    PeerAddr => $server,
    PeerPort => 6667,
    Proto => 'tcp',
    ) or die "Unable to connect\n";

#print "\x1b[0m\n";
print "\x1b[38;5;${color}m In Living Color!";

print $sock "NICK $nick\r\n";
print $sock "USER $login 8 *:New Deal Console IRC Client\r\n";

while (my $input = <%sock>) {
    if ($input =~ /004/) {
        last;
    }
    elsif ($input =~ /433/) {
        die "Nickname is already in use.";
    }
}

$cui->set_binding(sub {$menu->focus()}, "\cX");
$cui->set_binding( \&exit_dialog , "\cQ");
$cui->mainloop();

print $sock "JOIN #newdeal\r\n";
print $sock "PRIVMSG #newdeal :wow it works I think!\r\n";

sub mainloop() {
    while (my $input = <$sock>) {
        if ($color < 240) {
            $color++
        }
        else {
            $color = 2
        }
        $ircwindow.text($ircwindow.text() . "\x1b[38;5;${color}m");
        
        chop $input;
        if ($input =~ /^PING(.*)*/i) {
            print $sock "PONG $1 $1\r\n";
            $ircwindow.text($ircwindow.text() . "$input\n");
            $ircwindow.draw();
        }
        else {
            $ircwindow.text($ircwindow.text() . "$input\n");
            $ircwindow.draw();
        }
    }
}

print "Goodbye!\n";

close($sock);
