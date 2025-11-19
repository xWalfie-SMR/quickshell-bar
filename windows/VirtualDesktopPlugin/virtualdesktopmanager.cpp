#include "virtualdesktopmanager.h"
#include <Windows.h>
#include <QVariantMap>
#include <QDebug>
#include <shellapi.h>

// Structure to hold window enumeration data
struct EnumWindowsData {
    QVariantList* windows;
    HWND activeWindow;
};

// Callback for EnumWindows
BOOL CALLBACK EnumWindowsProc(HWND hwnd, LPARAM lParam) {
    EnumWindowsData* data = reinterpret_cast<EnumWindowsData*>(lParam);
    
    if (!IsWindowVisible(hwnd))
        return TRUE;
    
    // Skip windows without titles or with empty titles
    WCHAR title[256];
    GetWindowTextW(hwnd, title, 256);
    if (wcslen(title) == 0)
        return TRUE;
    
    // Skip certain window classes
    WCHAR className[256];
    GetClassNameW(hwnd, className, 256);
    QString classStr = QString::fromWCharArray(className);
    if (classStr == "Shell_TrayWnd" || classStr == "Progman")
        return TRUE;
    
    QVariantMap windowInfo;
    windowInfo["title"] = QString::fromWCharArray(title);
    windowInfo["hwnd"] = (qulonglong)hwnd;
    windowInfo["isActive"] = (hwnd == data->activeWindow);
    
    data->windows->append(windowInfo);
    return TRUE;
}

VirtualDesktopManager::VirtualDesktopManager(QObject *parent)
    : QObject(parent), m_currentDesktop(0)
{
    m_updateTimer = new QTimer(this);
    connect(m_updateTimer, &QTimer::timeout, this, &VirtualDesktopManager::updateWindows);
    connect(m_updateTimer, &QTimer::timeout, this, &VirtualDesktopManager::updateDesktops);
    m_updateTimer->start(500); // Update every 500ms
    
    initializeDesktops();
    updateWindows();
    updateDesktops();
}

VirtualDesktopManager::~VirtualDesktopManager()
{
}

QVariantList VirtualDesktopManager::windows() const
{
    return m_windows;
}

QString VirtualDesktopManager::activeWindowTitle() const
{
    return m_activeWindowTitle;
}

QVariantList VirtualDesktopManager::desktops() const
{
    return m_desktops;
}

int VirtualDesktopManager::currentDesktop() const
{
    return m_currentDesktop;
}

void VirtualDesktopManager::activateWindow(int index)
{
    if (index < 0 || index >= m_windows.size())
        return;
    
    QVariantMap windowInfo = m_windows[index].toMap();
    HWND hwnd = (HWND)windowInfo["hwnd"].toULongLong();
    
    if (IsIconic(hwnd))
        ShowWindow(hwnd, SW_RESTORE);
    
    SetForegroundWindow(hwnd);
}

void VirtualDesktopManager::switchToDesktop(int index)
{
    if (index < 0 || index >= m_desktops.size())
        return;
    
    switchDesktopViaKeysimulation(index);
}

void VirtualDesktopManager::updateWindows()
{
    QVariantList newWindows;
    HWND activeWnd = GetForegroundWindow();
    
    EnumWindowsData data;
    data.windows = &newWindows;
    data.activeWindow = activeWnd;
    
    EnumWindows(EnumWindowsProc, (LPARAM)&data);
    
    // Get active window title
    WCHAR activeTitle[256] = {0};
    if (activeWnd) {
        GetWindowTextW(activeWnd, activeTitle, 256);
    }
    QString newActiveTitle = QString::fromWCharArray(activeTitle);
    
    if (newWindows != m_windows) {
        m_windows = newWindows;
        emit windowsChanged();
    }
    
    if (newActiveTitle != m_activeWindowTitle) {
        m_activeWindowTitle = newActiveTitle;
        emit activeWindowChanged();
    }
}

void VirtualDesktopManager::updateDesktops()
{
    int activeDesktop = getActiveDesktop();
    if (activeDesktop != m_currentDesktop) {
        m_currentDesktop = activeDesktop;
        emit currentDesktopChanged();
    }
    
    QVariantList newDesktops;
    for (int i = 0; i < 4; ++i) {
        QVariantMap desktopInfo;
        desktopInfo["index"] = i;
        desktopInfo["isActive"] = (i == m_currentDesktop);
        newDesktops.append(desktopInfo);
    }
    
    if (newDesktops != m_desktops) {
        m_desktops = newDesktops;
        emit desktopsChanged();
    }
}

void VirtualDesktopManager::initializeDesktops()
{
    for (int i = 0; i < 4; ++i) {
        QVariantMap desktopInfo;
        desktopInfo["index"] = i;
        desktopInfo["isActive"] = (i == 0);
        m_desktops.append(desktopInfo);
    }
}

int VirtualDesktopManager::getActiveDesktop()
{
    HWND hwnd = GetForegroundWindow();
    if (!hwnd)
        return 0;
    
    char buffer[256] = {0};
    GetWindowTextA(hwnd, buffer, sizeof(buffer) - 1);
    
    DWORD processId;
    GetWindowThreadProcessId(hwnd, &processId);
    
    return processId % 4;
}

void VirtualDesktopManager::switchDesktopViaKeysimulation(int desktopIndex)
{
    INPUT inputs[6] = {};
    
    inputs[0].type = INPUT_KEYBOARD;
    inputs[0].ki.wVk = VK_LWIN;
    inputs[0].ki.dwFlags = 0;
    
    inputs[1].type = INPUT_KEYBOARD;
    inputs[1].ki.wVk = VK_CONTROL;
    inputs[1].ki.dwFlags = 0;
    
    inputs[2].type = INPUT_KEYBOARD;
    inputs[2].ki.wVk = VK_LEFT + desktopIndex;
    inputs[2].ki.dwFlags = 0;
    
    inputs[3].type = INPUT_KEYBOARD;
    inputs[3].ki.wVk = VK_LEFT + desktopIndex;
    inputs[3].ki.dwFlags = KEYEVENTF_KEYUP;
    
    inputs[4].type = INPUT_KEYBOARD;
    inputs[4].ki.wVk = VK_CONTROL;
    inputs[4].ki.dwFlags = KEYEVENTF_KEYUP;
    
    inputs[5].type = INPUT_KEYBOARD;
    inputs[5].ki.wVk = VK_LWIN;
    inputs[5].ki.dwFlags = KEYEVENTF_KEYUP;
    
    SendInput(6, inputs, sizeof(INPUT));
}
