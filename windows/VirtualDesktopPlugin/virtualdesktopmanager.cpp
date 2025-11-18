#include "virtualdesktopmanager.h"
#include <Windows.h>
#include <QVariantMap>
#include <QDebug>

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
    : QObject(parent)
{
    m_updateTimer = new QTimer(this);
    connect(m_updateTimer, &QTimer::timeout, this, &VirtualDesktopManager::updateWindows);
    m_updateTimer->start(500); // Update every 500ms
    
    updateWindows();
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
