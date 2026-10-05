// Compile the actual CliThread with minimal server doubles and real readline.
#include <cstdio>
#include <iostream>
#include <cstdlib>
#include <optional>
#include <string>
#include <unistd.h>
#include <readline/readline.h>
#include <readline/history.h>
#define TRINITY_PLATFORM 1
#define TRINITY_PLATFORM_WINDOWS 2
constexpr int SHUTDOWN_EXIT_CODE=0;
constexpr char CLI_PREFIX[]="SF> ";
template<class T> using Optional=std::optional<T>;
struct World
{
    static inline unsigned polls=0,commands=0;
    static inline bool stopped=false;
    static bool IsStopped(){return stopped || ++polls>4;}
    static void StopNow(int){stopped=true;}
    template<class T> void QueueCliCommand(T* p){++commands;delete p;}
} world;
World* sWorld=&world;
struct Config{bool GetBoolDefault(char const*,bool){return false;}} config;
Config* sConfigMgr=&config;
void utf8print(void*,char const*){}
void commandFinished(void*,bool){}
struct CliCommandHolder
{
    CliCommandHolder(void*,char const*,void(*)(void*,char const*),void(*)(void*,bool)){}
};
Optional<std::size_t> RemoveCRLF(std::string&){return std::nullopt;}
namespace Trinity::Impl::Readline
{
    char** cli_completion(char const*,int,int){return nullptr;}
    int cli_hook_func(){return 0;}
}
#include "cli-under-test.inc"
int main(int argc,char** argv)
{
    unsigned expected=argc>1 ? std::atoi(argv[1]) : 0;
    CliThread();
    if(World::stopped || World::commands!=expected || World::polls>expected+2)
    {
        std::fprintf(stderr,"FAIL: EOF stopped world or repeated console loop: polls=%u commands=%u stopped=%d\n",
            World::polls,World::commands,World::stopped);
        return 1;
    }
    std::puts("CLI EOF: passed (world remains running, console thread exits)");
}
