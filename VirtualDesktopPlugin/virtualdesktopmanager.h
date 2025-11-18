#ifndef VIRTUALDESKTOPMANAGER_H
#define VIRTUALDESKTOPMANAGER_H

#include <QObject>
#include <QTimer>

class VirtualDesktopManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int currentDesktop READ currentDesktop NOTIFY currentDesktopChanged)
    Q_PROPERTY(int desktopCount READ desktopCount NOTIFY desktopCountChanged)

public:
    explicit VirtualDesktopManager(QObject *parent = nullptr);
    ~VirtualDesktopManager();

    int currentDesktop() const;
    int desktopCount() const;

    Q_INVOKABLE void switchToDesktop(int desktopNumber);

signals:
    void currentDesktopChanged();
    void desktopCountChanged();

private slots:
    void pollDesktopState();

private:
    void initializeVirtualDesktops();
    void cleanupVirtualDesktops();
    int detectCurrentDesktop();
    int detectDesktopCount();

    int m_currentDesktop = 1;
    int m_desktopCount = 10;
    QTimer *m_pollTimer;
    void *m_serviceProvider = nullptr;
    void *m_desktopManager = nullptr;
};

#endif // VIRTUALDESKTOPMANAGER_H
