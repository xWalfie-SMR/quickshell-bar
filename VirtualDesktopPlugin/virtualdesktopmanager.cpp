#include "virtualdesktopmanager.h"
#include <Windows.h>
#include <shobjidl.h>
#include <wrl/client.h>

using namespace Microsoft::WRL;

// VK_0 not defined in some SDKs
#ifndef VK_0
#define VK_0 0x30
#endif

VirtualDesktopManager::VirtualDesktopManager(QObject *parent)
    : QObject(parent)
{
    CoInitialize(nullptr);
    initializeVirtualDesktops();

    m_pollTimer = new QTimer(this);
    connect(m_pollTimer, &QTimer::timeout, this, &VirtualDesktopManager::pollDesktopState);
    m_pollTimer->start(200);
}

VirtualDesktopManager::~VirtualDesktopManager()
{
    cleanupVirtualDesktops();
    CoUninitialize();
}

void VirtualDesktopManager::initializeVirtualDesktops()
{
    // Use the CLSID_VirtualDesktopManager from shobjidl.h
    HRESULT hr = CoCreateInstance(
        CLSID_VirtualDesktopManager,
        nullptr,
        CLSCTX_ALL,
        __uuidof(IVirtualDesktopManager),
        &m_desktopManager);

    if (SUCCEEDED(hr)) {
        m_desktopCount = detectDesktopCount();
        m_currentDesktop = detectCurrentDesktop();
    }
}

void VirtualDesktopManager::cleanupVirtualDesktops()
{
    if (m_desktopManager) {
        static_cast<IVirtualDesktopManager*>(m_desktopManager)->Release();
        m_desktopManager = nullptr;
    }
}

int VirtualDesktopManager::currentDesktop() const
{
    return m_currentDesktop;
}

int VirtualDesktopManager::desktopCount() const
{
    return m_desktopCount;
}

void VirtualDesktopManager::switchToDesktop(int desktopNumber)
{
    if (desktopNumber < 1 || desktopNumber > m_desktopCount)
        return;

    // Use keyboard shortcut simulation as COM API doesn't provide direct switching
    INPUT inputs[4] = {};
    
    // Win key down
    inputs[0].type = INPUT_KEYBOARD;
    inputs[0].ki.wVk = VK_LWIN;
    
    // Ctrl key down
    inputs[1].type = INPUT_KEYBOARD;
    inputs[1].ki.wVk = VK_CONTROL;
    
    // Desktop number
    inputs[2].type = INPUT_KEYBOARD;
    inputs[2].ki.wVk = VK_0 + desktopNumber;
    
    // Release all
    inputs[3].type = INPUT_KEYBOARD;
    inputs[3].ki.wVk = VK_0 + desktopNumber;
    inputs[3].ki.dwFlags = KEYEVENTF_KEYUP;
    
    SendInput(4, inputs, sizeof(INPUT));
    
    // Release Ctrl
    INPUT release1 = {};
    release1.type = INPUT_KEYBOARD;
    release1.ki.wVk = VK_CONTROL;
    release1.ki.dwFlags = KEYEVENTF_KEYUP;
    SendInput(1, &release1, sizeof(INPUT));
    
    // Release Win
    INPUT release2 = {};
    release2.type = INPUT_KEYBOARD;
    release2.ki.wVk = VK_LWIN;
    release2.ki.dwFlags = KEYEVENTF_KEYUP;
    SendInput(1, &release2, sizeof(INPUT));

    m_currentDesktop = desktopNumber;
    emit currentDesktopChanged();
}

void VirtualDesktopManager::pollDesktopState()
{
    int newDesktop = detectCurrentDesktop();
    if (newDesktop != m_currentDesktop && newDesktop > 0) {
        m_currentDesktop = newDesktop;
        emit currentDesktopChanged();
    }
}

int VirtualDesktopManager::detectCurrentDesktop()
{
    // Since Windows doesn't expose current desktop easily,
    // we'll track it based on our switches
    return m_currentDesktop;
}

int VirtualDesktopManager::detectDesktopCount()
{
    // Default to 10 workspaces
    return 10;
}
