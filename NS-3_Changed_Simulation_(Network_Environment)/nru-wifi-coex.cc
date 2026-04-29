#include "ns3/applications-module.h"
#include "ns3/core-module.h"
#include "ns3/internet-module.h"
#include "ns3/mobility-module.h"
#include "ns3/network-module.h"
#include "ns3/propagation-loss-model.h"
#include "ns3/wifi-module.h"

#include <cmath>
#include <iostream>
#include <random>
#include <sstream>
#include <string>
#include <vector>

using namespace ns3;

NS_LOG_COMPONENT_DEFINE("NruWifiCoex");

struct NodeStats
{
    uint64_t rxBytes{0};
    uint64_t rxPackets{0};
};
std::vector<NodeStats> g_nruStats;
std::vector<NodeStats> g_wifiStats;

static const double RTS_CTS_OVERHEAD_US = 224.0;
std::vector<bool> g_wifiBlocked;

void UnblockWifiMac(uint32_t idx)
{
    if (idx < g_wifiBlocked.size())
        g_wifiBlocked[idx] = false;
}

void WifiAckedMpduCallback(uint32_t idx, Ptr<const WifiMpdu>)
{
    if (idx < g_wifiBlocked.size())
    {
        g_wifiBlocked[idx] = true;
        Simulator::Schedule(MicroSeconds(RTS_CTS_OVERHEAD_US),
                            &UnblockWifiMac, idx);
    }
}

void NruRxCallback(uint32_t idx, Ptr<const Packet> pkt, const Address&)
{
    g_nruStats[idx].rxBytes   += pkt->GetSize();
    g_nruStats[idx].rxPackets += 1;
}

void WifiRxCallback(uint32_t idx, Ptr<const Packet> pkt, const Address&)
{
    g_wifiStats[idx].rxBytes   += pkt->GetSize();
    g_wifiStats[idx].rxPackets += 1;
}

double SensingDistToCcaThreshold(double distMeters)
{
    const double freq   = 5.18e9;
    const double c      = 3e8;
    const double lambda = c / freq;
    const double txPow  = 20.0;
    double fspl = 20.0 * std::log10(4.0 * M_PI * distMeters / lambda);
    return txPow - fspl;
}

int main(int argc, char* argv[])
{
    double   arrivalRate  = 3.0;
    uint32_t runId        = 0;
    double   simTime      = 5.0;
    double   nruDensity   = 0.0001;
    double   wifiDensity  = 0.0001;
    double   nruSenseDist = 100.0;
    double   nruTxDist    = 80.0;
    double   wifiSenseDist= 90.0;
    double   wifiTxDist   = 70.0;
    double   nruDataRate  = 100.0;
    double   wifiDataRate = 54.0;
    double   areaSize     = 1000.0;

    CommandLine cmd;
    cmd.AddValue("arrivalRate",   "Packet arrival rate (packets/ms)", arrivalRate);
    cmd.AddValue("runId",         "RNG run index",                    runId);
    cmd.AddValue("simTime",       "Simulation time (s)",              simTime);
    cmd.AddValue("nruDensity",    "NR-U gNB density (nodes/m2)",      nruDensity);
    cmd.AddValue("wifiDensity",   "WiFi AP density (nodes/m2)",       wifiDensity);
    cmd.AddValue("nruSenseDist",  "NR-U sensing distance (m)",        nruSenseDist);
    cmd.AddValue("nruTxDist",     "NR-U tx distance (m)",             nruTxDist);
    cmd.AddValue("wifiSenseDist", "WiFi sensing distance (m)",        wifiSenseDist);
    cmd.AddValue("wifiTxDist",    "WiFi tx distance (m)",             wifiTxDist);
    cmd.AddValue("nruDataRate",   "NR-U equivalent rate (Mbps)",      nruDataRate);
    cmd.AddValue("wifiDataRate",  "WiFi channel rate (Mbps)",         wifiDataRate);
    cmd.AddValue("areaSize",      "Deployment area side (m)",         areaSize);
    cmd.Parse(argc, argv);

    double nruCcaThreshold  = SensingDistToCcaThreshold(nruSenseDist);
    double wifiCcaThreshold = SensingDistToCcaThreshold(wifiSenseDist);
    static const double TX_POWER_DBM   = 20.0;
    static const double PHY_RATE_MBPS  = 54.0;
    static const double WIFI_PKT_BYTES = 1500.0;
    double nruPktBytes = WIFI_PKT_BYTES * (PHY_RATE_MBPS / nruDataRate);

    RngSeedManager::SetSeed(42 + runId);
    RngSeedManager::SetRun(runId + 1);
    std::mt19937 rng(42 + runId);
    std::uniform_real_distribution<double> uniX(0.0, areaSize);
    std::uniform_real_distribution<double> uniY(0.0, areaSize);

    double area = areaSize * areaSize;
    std::poisson_distribution<uint32_t> poisNru (nruDensity  * area);
    std::poisson_distribution<uint32_t> poisWifi(wifiDensity * area);
    uint32_t nNru  = std::max(1u, poisNru (rng));
    uint32_t nWifi = std::max(1u, poisWifi(rng));

    NodeContainer nruAPs,  nruUsers;
    NodeContainer wifiAPs, wifiUsers;
    nruAPs.Create(nNru);   nruUsers.Create(nNru);
    wifiAPs.Create(nWifi); wifiUsers.Create(nWifi);

    MobilityHelper mob;
    mob.SetMobilityModel("ns3::ConstantPositionMobilityModel");
    mob.Install(nruAPs);  mob.Install(nruUsers);
    mob.Install(wifiAPs); mob.Install(wifiUsers);

    std::uniform_real_distribution<double> uniAngle(0.0, 2.0 * M_PI);
    std::uniform_real_distribution<double> uniUnit (0.0, 1.0);

    for (uint32_t i = 0; i < nNru; i++)
    {
        double x = uniX(rng), y = uniY(rng);
        nruAPs.Get(i)->GetObject<MobilityModel>()->SetPosition(Vector(x, y, 0));
        double r = nruTxDist * std::sqrt(uniUnit(rng));
        double a = uniAngle(rng);
        nruUsers.Get(i)->GetObject<MobilityModel>()->SetPosition(
            Vector(x + r*std::cos(a), y + r*std::sin(a), 0));
    }
    for (uint32_t i = 0; i < nWifi; i++)
    {
        double x = uniX(rng), y = uniY(rng);
        wifiAPs.Get(i)->GetObject<MobilityModel>()->SetPosition(Vector(x, y, 0));
        double r = wifiTxDist * std::sqrt(uniUnit(rng));
        double a = uniAngle(rng);
        wifiUsers.Get(i)->GetObject<MobilityModel>()->SetPosition(
            Vector(x + r*std::cos(a), y + r*std::sin(a), 0));
    }

    YansWifiChannelHelper channel;
    channel.SetPropagationDelay("ns3::ConstantSpeedPropagationDelayModel");
    channel.AddPropagationLoss("ns3::FriisPropagationLossModel",
                               "Frequency", DoubleValue(5.18e9));
    Ptr<YansWifiChannel> sharedCh = channel.Create();

    YansWifiPhyHelper nruPhy, wifiPhy;
    nruPhy.SetChannel (sharedCh); wifiPhy.SetChannel(sharedCh);
    nruPhy.Set ("TxPowerStart",   DoubleValue(TX_POWER_DBM));
    nruPhy.Set ("TxPowerEnd",     DoubleValue(TX_POWER_DBM));
    nruPhy.Set ("CcaEdThreshold", DoubleValue(nruCcaThreshold));
    nruPhy.Set ("RxSensitivity",  DoubleValue(nruCcaThreshold));
    wifiPhy.Set("TxPowerStart",   DoubleValue(TX_POWER_DBM));
    wifiPhy.Set("TxPowerEnd",     DoubleValue(TX_POWER_DBM));
    wifiPhy.Set("CcaEdThreshold", DoubleValue(wifiCcaThreshold));
    wifiPhy.Set("RxSensitivity",  DoubleValue(wifiCcaThreshold));

    WifiHelper nruWifi, wifiWifi;
    nruWifi.SetStandard(WIFI_STANDARD_80211a);
    nruWifi.SetRemoteStationManager("ns3::ConstantRateWifiManager",
                                    "DataMode",    StringValue("OfdmRate54Mbps"),
                                    "ControlMode", StringValue("OfdmRate6Mbps"));
    wifiWifi.SetStandard(WIFI_STANDARD_80211a);
    wifiWifi.SetRemoteStationManager("ns3::ConstantRateWifiManager",
                                     "DataMode",    StringValue("OfdmRate54Mbps"),
                                     "ControlMode", StringValue("OfdmRate6Mbps"));

    WifiMacHelper nruMac, wifiMac;
    nruMac.SetType ("ns3::AdhocWifiMac", "QosSupported", BooleanValue(true));
    wifiMac.SetType("ns3::AdhocWifiMac", "QosSupported", BooleanValue(true));
    Config::SetDefault("ns3::WifiRemoteStationManager::RtsCtsThreshold",
                       UintegerValue(65535));

    NetDeviceContainer nruApDev   = nruWifi.Install (nruPhy,  nruMac,  nruAPs);
    NetDeviceContainer nruStaDev  = nruWifi.Install (nruPhy,  nruMac,  nruUsers);
    NetDeviceContainer wifiApDev  = wifiWifi.Install(wifiPhy, wifiMac, wifiAPs);
    NetDeviceContainer wifiStaDev = wifiWifi.Install(wifiPhy, wifiMac, wifiUsers);

    for (uint32_t i = 0; i < nruApDev.GetN(); i++)
    {
        Ptr<QosTxop> edca = DynamicCast<WifiNetDevice>(nruApDev.Get(i))
                                ->GetMac()->GetQosTxop(AC_BE);
        edca->SetMinCw(15); edca->SetMaxCw(1023);
        edca->SetAifsn(2);  edca->SetTxopLimit(MicroSeconds(0));
    }
    for (uint32_t i = 0; i < wifiApDev.GetN(); i++)
    {
        Ptr<QosTxop> edca = DynamicCast<WifiNetDevice>(wifiApDev.Get(i))
                                ->GetMac()->GetQosTxop(AC_BE);
        edca->SetMinCw(15); edca->SetMaxCw(1023);
        edca->SetAifsn(2);  edca->SetTxopLimit(MicroSeconds(0));
    }

    InternetStackHelper inet;
    inet.Install(nruAPs);  inet.Install(nruUsers);
    inet.Install(wifiAPs); inet.Install(wifiUsers);

    Ipv4AddressHelper ipv4;
    std::vector<Ipv4Address> nruUserAddrs(nNru), wifiUserAddrs(nWifi);

    for (uint32_t i = 0; i < nNru; i++)
    {
        std::ostringstream ss;
        ss << "10.1." << (i/64) << "." << ((i%64)*4);
        ipv4.SetBase(ss.str().c_str(), "255.255.255.252");
        NetDeviceContainer p; p.Add(nruApDev.Get(i)); p.Add(nruStaDev.Get(i));
        nruUserAddrs[i] = ipv4.Assign(p).GetAddress(1);
    }
    for (uint32_t i = 0; i < nWifi; i++)
    {
        std::ostringstream ss;
        ss << "10.2." << (i/64) << "." << ((i%64)*4);
        ipv4.SetBase(ss.str().c_str(), "255.255.255.252");
        NetDeviceContainer p; p.Add(wifiApDev.Get(i)); p.Add(wifiStaDev.Get(i));
        wifiUserAddrs[i] = ipv4.Assign(p).GetAddress(1);
    }

    g_nruStats.resize (nNru);
    g_wifiStats.resize(nWifi);
    g_wifiBlocked.resize(nWifi, false);

    uint16_t port       = 9;
    double   arrPerSec  = arrivalRate * 1000.0;
    double   meanIAT    = 1.0 / arrPerSec;
    double   phyRateBps = PHY_RATE_MBPS * 1e6;

    for (uint32_t i = 0; i < nNru; i++)
    {
        PacketSinkHelper sink("ns3::UdpSocketFactory",
                              InetSocketAddress(Ipv4Address::GetAny(), port));
        ApplicationContainer sinkApp = sink.Install(nruUsers.Get(i));
        sinkApp.Start(Seconds(0.0)); sinkApp.Stop(Seconds(simTime));
        Ptr<PacketSink> sinkPtr = DynamicCast<PacketSink>(sinkApp.Get(0));

        double onT  = (nruPktBytes * 8.0) / phyRateBps;
        double offM = std::max(1e-9, meanIAT - onT);

        OnOffHelper onoff("ns3::UdpSocketFactory",
                          InetSocketAddress(nruUserAddrs[i], port));
        onoff.SetConstantRate(DataRate(static_cast<uint64_t>(phyRateBps)));
        onoff.SetAttribute("PacketSize", UintegerValue((uint32_t)nruPktBytes));
        onoff.SetAttribute("OnTime",  StringValue(
            "ns3::ConstantRandomVariable[Constant=" + std::to_string(onT) + "]"));
        onoff.SetAttribute("OffTime", StringValue(
            "ns3::ExponentialRandomVariable[Mean=" + std::to_string(offM) + "]"));

        ApplicationContainer src = onoff.Install(nruAPs.Get(i));
        src.Start(Seconds(0.1)); src.Stop(Seconds(simTime));

        uint32_t idx = i;
        sinkPtr->TraceConnectWithoutContext("Rx",
            MakeBoundCallback(&NruRxCallback, idx));
    }

    for (uint32_t i = 0; i < nWifi; i++)
    {
        PacketSinkHelper sink("ns3::UdpSocketFactory",
                              InetSocketAddress(Ipv4Address::GetAny(), port+1));
        ApplicationContainer sinkApp = sink.Install(wifiUsers.Get(i));
        sinkApp.Start(Seconds(0.0)); sinkApp.Stop(Seconds(simTime));
        Ptr<PacketSink> sinkPtr = DynamicCast<PacketSink>(sinkApp.Get(0));

        double onT  = (WIFI_PKT_BYTES * 8.0) / phyRateBps;
        double offM = std::max(1e-9, meanIAT - onT);

        OnOffHelper onoff("ns3::UdpSocketFactory",
                          InetSocketAddress(wifiUserAddrs[i], port+1));
        onoff.SetConstantRate(DataRate(static_cast<uint64_t>(phyRateBps)));
        onoff.SetAttribute("PacketSize", UintegerValue((uint32_t)WIFI_PKT_BYTES));
        onoff.SetAttribute("OnTime",  StringValue(
            "ns3::ConstantRandomVariable[Constant=" + std::to_string(onT) + "]"));
        onoff.SetAttribute("OffTime", StringValue(
            "ns3::ExponentialRandomVariable[Mean=" + std::to_string(offM) + "]"));

        ApplicationContainer src = onoff.Install(wifiAPs.Get(i));
        src.Start(Seconds(0.1)); src.Stop(Seconds(simTime));

        uint32_t idx = i;
        sinkPtr->TraceConnectWithoutContext("Rx",
            MakeBoundCallback(&WifiRxCallback, idx));

        Ptr<WifiNetDevice> dev = DynamicCast<WifiNetDevice>(wifiApDev.Get(i));
        dev->GetMac()->TraceConnectWithoutContext("AckedMpdu",
            MakeBoundCallback(&WifiAckedMpduCallback, idx));
    }

    Simulator::Stop(Seconds(simTime));
    Simulator::Run();
    Simulator::Destroy();

    double measureTime = simTime - 0.1;

    uint64_t nruBytes = 0;
    uint64_t nruPkts  = 0;
    for (auto& s : g_nruStats) { nruBytes += s.rxBytes; nruPkts += s.rxPackets; }
    double nruTp = (nNru > 0 && nruBytes > 0)
        ? ((double)nruBytes * 8.0 / measureTime / 1e6 / nNru
           * (nruDataRate / PHY_RATE_MBPS))
        : 0.0;

    double nruPktBits = nruPktBytes * 8.0 * (nruDataRate / PHY_RATE_MBPS);
    double nruDly = (nruTp > 0)
        ? (nruPktBits / (nruTp * 1e6) * 1000.0)
        : 0.0;

    uint64_t wifiBytes = 0;
    uint64_t wifiPkts  = 0;
    for (auto& s : g_wifiStats) { wifiBytes += s.rxBytes; wifiPkts += s.rxPackets; }
    double wifiTp = (nWifi > 0 && wifiBytes > 0)
        ? ((double)wifiBytes * 8.0 / measureTime / 1e6 / nWifi)
        : 0.0;

    double wifiPktBits = WIFI_PKT_BYTES * 8.0;
    double wifiDly = (wifiTp > 0)
        ? (wifiPktBits / (wifiTp * 1e6) * 1000.0)
        : 0.0;

    std::cout << "NRU_THROUGHPUT "  << nruTp   << "\n";
    std::cout << "NRU_DELAY "       << nruDly  << "\n";
    std::cout << "WIFI_THROUGHPUT " << wifiTp  << "\n";
    std::cout << "WIFI_DELAY "      << wifiDly << "\n";
    std::cout << "NRU_NODES "       << nNru    << "\n";
    std::cout << "WIFI_NODES "      << nWifi   << "\n";

    return 0;
}