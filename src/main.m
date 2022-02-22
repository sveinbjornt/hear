//
//  main.m
//  listen
//
//  Created by Sveinbjorn Thordarson on 18.2.2022.
//

#import <getopt.h>

#import <Foundation/Foundation.h>

#import "Common.h"
#import "Listen.h"

static void PrintVersion(void);
static void PrintHelp(void);


static const char optstring[] = "li:f:rhv";

static struct option long_options[] = {

    {"list",                      required_argument,  0, 'l'}, // List available languages for STT
    {"input",                     required_argument,  0, 'i'}, // Input (file path or - for stdin)
    {"format",                    required_argument,  0, 'f'}, // Format (of input file or data)
    //{"raw",                       required_argument,  0, 'r'}, // Raw output
    
    {"help",                      no_argument,        0, 'h'},
    {"version",                   no_argument,        0, 'v'},
    
    {0,                           0,                  0,  0 }
};


int main(int argc, const char * argv[]) { @autoreleasepool {
    
    NSString *inputFilename;
    NSString *inputFormat;
    
    int optch;
    int long_index = 0;
    while ((optch = getopt_long(argc, (char *const *)argv, optstring, long_options, &long_index)) != -1) {
        switch (optch) {
            
            // Print list of supported languages
            case 'l':
                [Listen printSupportedLanguages];
                exit(EXIT_SUCCESS);
                break;
            
            // Input filename ("-" for stdin)
            case 'i':
                inputFilename = @(optarg);
                break;
            
            // Input audio format
            case 'f':
                inputFormat = @(optarg);
                break;
            
            // Print version
            case 'v':
            {
                PrintVersion();
                exit(EXIT_SUCCESS);
            }
                break;
            
            // Print help text with list of options
            case 'h':
            default:
            {
                PrintHelp();
                exit(EXIT_SUCCESS);
            }
                break;
        }
    }

    Listen *listener = [Listen new];
    [[NSApplication sharedApplication] setDelegate:listener];
    [[NSApplication sharedApplication] run];

    return 0;
}}

#pragma mark -

static void PrintVersion(void) {
    NSPrint(@"hear version %@", PROGRAM_VERSION);
}

static void PrintHelp(void) {
    PrintVersion();
    
    NSPrint(@"\n\
platypus [OPTIONS] scriptPath [destinationPath]\n\
\n\
Options:\n\
\n\
    -O --generate-profile              Generate a profile instead of an app\n\
\n\
    -P --load-profile [profilePath]    Load settings from profile document\n\
    -a --name [name]                   Set name of application bundle\n\
    -o --interface-type [type]         Set interface type. See man page for accepted types\n\
    -p --interpreter [interpreterPath] Set interpreter for script\n\
\n\
    -i --app-icon [iconPath]           Set icon for application\n\
    -u --author [author]               Set name of application author\n\
    -Q --document-icon [iconPath]      Set icon for documents\n\
    -V --app-version [version]         Set version of application\n\
    -I --bundle-identifier [idstr]     Set bundle identifier (e.g. org.yourname.appname)\n\
\n\
    -A --admin-privileges              App runs with Administrator privileges\n\
    -D --droppable                     App accepts dropped files as arguments to script\n\
    -F --text-droppable                App accepts dropped text passed to script via STDIN\n\
    -Z --file-prompt                   App presents an open file dialog when launched\n\
    -N --service                       App registers as a Mac OS X Service\n\
    -B --background                    App runs in background (LSUIElement)\n\
    -R --quit-after-execution          App quits after executing script\n\
\n\
    -b --text-background-color [color] Set background color of text view (e.g. '#ffffff')\n\
    -g --text-foreground-color [color] Set foreground color of text view (e.g. '#000000')\n\
    -n --text-font [fontName]          Set font for text view (e.g. 'Monaco 10')\n\
    -X --suffixes [suffixes]           Set suffixes handled by app, separated by |\n\
    -T --uniform-type-identifiers      Set uniform type identifiers handled by app, separated by |\n\
    -U --uri-schemes                   Set URI schemes handled by app, separated by |\n\
    -G --interpreter-args [arguments]  Set arguments for script interpreter, separated by |\n\
    -C --script-args [arguments]       Set arguments for script, separated by |\n\
\n\
    -K --status-item-kind [kind]       Set Status Item kind ('Icon' or 'Text')\n\
    -Y --status-item-title [title]     Set title of Status Item\n\
    -L --status-item-icon [imagePath]  Set icon of Status Item\n\
    -c --status-item-sysfont           Status Item should use the system font for menu item text\n\
    -q --status-item-template-icon     Status Item icon should be treated as a template by AppKit\n\
\n\
    -f --bundled-file [filePath]       Add a bundled file or files (paths separated by \"|\")\n\
    \n\
    -y --overwrite                     Overwrite any file/folder at destination path\n\
    -d --symlink                       Symlink to script and bundled files instead of copying\n\
    -l --optimize-nib                  Strip and compile bundled nib file to reduce size\n\
    -h --help                          Prints help\n\
    -v --version                       Prints program name and version\n\
\n\
For further details, see 'man hear'.");
}

