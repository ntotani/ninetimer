#include "AppDelegate.h"
#include "CCLuaEngine.h"
#include "SimpleAudioEngine.h"
#include "cocos2d.h"
#include "lua_module_register.h"

#if (CC_TARGET_PLATFORM != CC_PLATFORM_LINUX)
#include "ide-support/CodeIDESupport.h"
#endif

#if (COCOS2D_DEBUG > 0) && (CC_CODE_IDE_DEBUG_SUPPORT > 0)
#include "runtime/Runtime.h"
#endif

#include "network/HttpClient.h"
#include "tolua_fix.h"

using namespace CocosDenshion;

USING_NS_CC;
using namespace std;
using namespace network;

int fetch_icon_glue(lua_State* tolua_S)
{
    auto iconUrl = lua_tostring(tolua_S, 1);
    LUA_FUNCTION handler = toluafix_ref_function(tolua_S, 2, 0);
    auto req = new HttpRequest();
    req->setUrl(iconUrl);
    req->setRequestType(HttpRequest::Type::GET);
    req->setResponseCallback([tolua_S, iconUrl, handler](HttpClient* client, HttpResponse* res) {
        Image *image = new Image();
        image->autorelease();
        if (!res->isSucceed() || !image->initWithImageData(reinterpret_cast<unsigned char*>(&(res->getResponseData()->front())), res->getResponseData()->size())) {
            image->initWithImageFile("white.png");
        }
        Texture2D *texture = new Texture2D();
        texture->initWithImage(image);
        texture->autorelease();
        int nID = (texture) ? (int)texture->_ID : -1;
        int* pLuaID = (texture) ? &texture->_luaID : NULL;
        toluafix_pushusertype_ccobject(tolua_S, nID, pLuaID, (void*)texture, "cc.Texture2D");
        LuaEngine::getInstance()->getLuaStack()->executeFunctionByHandler(handler, 1);
        LuaEngine::getInstance()->removeScriptHandler(handler);
    });
    HttpClient::getInstance()->sendImmediate(req);
    req->release();
    return 0;
}

AppDelegate::AppDelegate()
{
}

AppDelegate::~AppDelegate()
{
    SimpleAudioEngine::end();

#if (COCOS2D_DEBUG > 0) && (CC_CODE_IDE_DEBUG_SUPPORT > 0)
    // NOTE:Please don't remove this call if you want to debug with Cocos Code IDE
    RuntimeEngine::getInstance()->end();
#endif
}

//if you want a different context,just modify the value of glContextAttrs
//it will takes effect on all platforms
void AppDelegate::initGLContextAttrs()
{
    //set OpenGL context attributions,now can only set six attributions:
    //red,green,blue,alpha,depth,stencil
    GLContextAttrs glContextAttrs = {8, 8, 8, 8, 24, 8};

    GLView::setGLContextAttrs(glContextAttrs);
}

bool AppDelegate::applicationDidFinishLaunching()
{
    // set default FPS
    Director::getInstance()->setAnimationInterval(1.0 / 60.0f);
   
    // register lua module
    auto engine = LuaEngine::getInstance();
    ScriptEngineManager::getInstance()->setScriptEngine(engine);
    lua_State* L = engine->getLuaStack()->getLuaState();
    lua_module_register(L);

    // If you want to use Quick-Cocos2d-X, please uncomment below code
    // register_all_quick_manual(L);

    LuaStack* stack = engine->getLuaStack();
    stack->setXXTEAKeyAndSign("2dxLua", strlen("2dxLua"), "XXTEA", strlen("XXTEA"));
    
    //register custom function
    lua_getglobal(stack->getLuaState(), "_G");
    lua_register(stack->getLuaState(), "fetchIcon", fetch_icon_glue);
    
#if (COCOS2D_DEBUG > 0) && (CC_CODE_IDE_DEBUG_SUPPORT > 0)
    // NOTE:Please don't remove this call if you want to debug with Cocos Code IDE
    RuntimeEngine::getInstance()->start();
    cocos2d::log("iShow!");
#else
    if (engine->executeScriptFile("src/main.lua"))
    {
        return false;
    }
#endif
    
    return true;
}

// This function will be called when the app is inactive. When comes a phone call,it's be invoked too
void AppDelegate::applicationDidEnterBackground()
{
    Director::getInstance()->stopAnimation();

    SimpleAudioEngine::getInstance()->pauseBackgroundMusic();
}

// this function will be called when the app is active again
void AppDelegate::applicationWillEnterForeground()
{
    Director::getInstance()->startAnimation();

    SimpleAudioEngine::getInstance()->resumeBackgroundMusic();
}
