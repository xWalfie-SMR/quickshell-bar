#ifndef VIRTUALDESKTOPMANAGER_H
#define VIRTUALDESKTOPMANAGER_H

#include <QObject>
#include <QTimer>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

class VirtualDesktopManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QVariantList windows READ windows NOTIFY windowsChanged)
    Q_PROPERTY(QString activeWindowTitle READ activeWindowTitle NOTIFY activeWindowChanged)

public:
    explicit VirtualDesktopManager(QObject *parent = nullptr);
    ~VirtualDesktopManager();

    QVariantList windows() const;
    QString activeWindowTitle() const;

    Q_INVOKABLE void activateWindow(int index);

signals:
    void windowsChanged();
    void activeWindowChanged();

private slots:
    void updateWindows();

private:
    QVariantList m_windows;
    QString m_activeWindowTitle;
    QTimer *m_updateTimer;
};

#endif // VIRTUALDESKTOPMANAGER_H
