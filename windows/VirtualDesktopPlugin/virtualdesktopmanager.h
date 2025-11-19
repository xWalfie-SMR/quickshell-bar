#ifndef VIRTUALDESKTOPMANAGER_H
#define VIRTUALDESKTOPMANAGER_H

#include <QObject>
#include <QTimer>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>
#include <Windows.h>

class VirtualDesktopManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QVariantList windows READ windows NOTIFY windowsChanged)
    Q_PROPERTY(QString activeWindowTitle READ activeWindowTitle NOTIFY activeWindowChanged)
    Q_PROPERTY(QVariantList desktops READ desktops NOTIFY desktopsChanged)
    Q_PROPERTY(int currentDesktop READ currentDesktop NOTIFY currentDesktopChanged)

public:
    explicit VirtualDesktopManager(QObject *parent = nullptr);
    ~VirtualDesktopManager();

    QVariantList windows() const;
    QString activeWindowTitle() const;
    QVariantList desktops() const;
    int currentDesktop() const;

    Q_INVOKABLE void activateWindow(int index);
    Q_INVOKABLE void switchToDesktop(int index);

signals:
    void windowsChanged();
    void activeWindowChanged();
    void desktopsChanged();
    void currentDesktopChanged();

private slots:
    void updateWindows();
    void updateDesktops();

private:
    QVariantList m_windows;
    QString m_activeWindowTitle;
    QVariantList m_desktops;
    int m_currentDesktop;
    QTimer *m_updateTimer;
    
    void initializeDesktops();
    int getActiveDesktop();
    void switchDesktopViaKeysimulation(int desktopIndex);
};

#endif // VIRTUALDESKTOPMANAGER_H
