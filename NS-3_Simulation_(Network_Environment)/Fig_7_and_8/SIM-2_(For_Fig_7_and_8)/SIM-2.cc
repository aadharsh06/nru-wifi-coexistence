#include "ns3/flow-monitor-module.h"
#include "ns3/core-module.h"
#include "ns3/network-module.h"
#include "ns3/applications-module.h"
#include "ns3/wifi-module.h"
#include "ns3/mobility-module.h"
#include "ns3/internet-module.h"

using namespace ns3;

NS_LOG_COMPONENT_DEFINE ("CoexistenceGrid");

static void GeneratePoissonTraffic (Ptr<Socket> socket, uint32_t pktSize, Ptr<ExponentialRandomVariable> expRv)
{
  Ptr<Packet> packet = Create<Packet> (pktSize);
  socket->Send (packet);

  Time nextArrival = Seconds (expRv->GetValue ());
  Simulator::Schedule (nextArrival, &GeneratePoissonTraffic, socket, pktSize, expRv);
}

int main (int argc, char *argv[])
{
  std::string dataRate = "50Mbps";
  uint32_t numWifiPairs = 25;
  uint32_t numNruPairs = 25;
  uint32_t rngRun = 1;

  double nruCca = -90.6;
  std::string nruDataMode = "HtMcs7";

  CommandLine cmd;
  cmd.AddValue ("dataRate", "Packet arrival rate", dataRate);
  cmd.AddValue ("nWifi", "Number of WiFi APs", numWifiPairs);
  cmd.AddValue ("nNru", "Number of NR-U gNBs", numNruPairs);
  cmd.AddValue ("rngRun", "Random seed run", rngRun);
  cmd.AddValue ("nruCca", "CCA Threshold for NR-U (dBm)", nruCca);
  cmd.AddValue ("nruDataMode", "802.11n MCS Index for NR-U", nruDataMode);
  cmd.Parse (argc, argv);

  Config::SetDefault ("ns3::WifiMacQueue::MaxSize", StringValue ("2p"));
  Config::SetDefault ("ns3::DropTailQueue<Packet>::MaxSize", StringValue ("2p"));

  Config::SetDefault ("ns3::PfifoFastQueueDisc::MaxSize", StringValue ("2p"));
  Config::SetDefault ("ns3::FqCoDelQueueDisc::MaxSize", StringValue ("2p"));

  RngSeedManager::SetSeed (1);
  RngSeedManager::SetRun (rngRun);

  std::cout << "\n[Locked Topology] " << numWifiPairs << " WiFi APs and " << numNruPairs << " NR-U gNBs." << std::endl;

  NodeContainer wifiTx, wifiRx, nruTx, nruRx;
  wifiTx.Create (numWifiPairs);
  wifiRx.Create (numWifiPairs);
  nruTx.Create (numNruPairs);
  nruRx.Create (numNruPairs);

  NodeContainer allNodes;
  allNodes.Add (wifiTx); allNodes.Add (wifiRx);
  allNodes.Add (nruTx); allNodes.Add (nruRx);

  YansWifiChannelHelper channel;
  channel.SetPropagationDelay ("ns3::ConstantSpeedPropagationDelayModel");
  channel.AddPropagationLoss ("ns3::LogDistancePropagationLossModel", "Exponent", DoubleValue (3.0));
  Ptr<YansWifiChannel> sharedChannel = channel.Create ();

  YansWifiPhyHelper wifiPhy;
  wifiPhy.SetChannel (sharedChannel);
  wifiPhy.Set ("TxPowerStart", DoubleValue (16.0));
  wifiPhy.Set ("TxPowerEnd", DoubleValue (16.0));

  wifiPhy.Set ("RxSensitivity", DoubleValue (-86.0));
  wifiPhy.Set ("CcaEdThreshold", DoubleValue (-89.3));

  WifiHelper wifiHelper;
  wifiHelper.SetStandard (WIFI_STANDARD_80211a);
  wifiHelper.SetRemoteStationManager ("ns3::ConstantRateWifiManager",
                                      "DataMode", StringValue ("OfdmRate54Mbps"),
                                      "ControlMode", StringValue ("OfdmRate24Mbps"),
                                      "RtsCtsThreshold", UintegerValue (100));
  WifiMacHelper wifiMac;
  wifiMac.SetType ("ns3::AdhocWifiMac");

  NetDeviceContainer wifiDevicesTx = wifiHelper.Install (wifiPhy, wifiMac, wifiTx);
  NetDeviceContainer wifiDevicesRx = wifiHelper.Install (wifiPhy, wifiMac, wifiRx);

  YansWifiPhyHelper nruPhy;
  nruPhy.SetChannel (sharedChannel);
  nruPhy.Set ("TxPowerStart", DoubleValue (16.0));
  nruPhy.Set ("TxPowerEnd", DoubleValue (16.0));

  nruPhy.Set ("RxSensitivity", DoubleValue (-87.7));
  nruPhy.Set ("CcaEdThreshold", DoubleValue (nruCca));

  WifiHelper nruHelper;
  nruHelper.SetStandard (WIFI_STANDARD_80211n);
  nruHelper.SetRemoteStationManager ("ns3::ConstantRateWifiManager",
                                      "DataMode", StringValue (nruDataMode),
                                      "ControlMode", StringValue ("HtMcs0"),
                                      "RtsCtsThreshold", UintegerValue (999999));

  WifiMacHelper nruMac;
  nruMac.SetType ("ns3::AdhocWifiMac", "BE_MaxAmpduSize", UintegerValue (0));

  NetDeviceContainer nruDevicesTx = nruHelper.Install (nruPhy, nruMac, nruTx);
  NetDeviceContainer nruDevicesRx = nruHelper.Install (nruPhy, nruMac, nruRx);

  NetDeviceContainer allDevices;
  allDevices.Add (wifiDevicesTx); allDevices.Add (wifiDevicesRx);
  allDevices.Add (nruDevicesTx); allDevices.Add (nruDevicesRx);

  MobilityHelper mobility;
  mobility.SetPositionAllocator ("ns3::RandomRectanglePositionAllocator",
                                   "X", StringValue ("ns3::UniformRandomVariable[Min=0.0|Max=300.0]"),
                                   "Y", StringValue ("ns3::UniformRandomVariable[Min=0.0|Max=300.0]"));
  mobility.SetMobilityModel ("ns3::ConstantPositionMobilityModel");
  mobility.Install (allNodes);

  for (uint32_t i = 0; i < numWifiPairs; i++) {
      Vector posW = wifiTx.Get(i)->GetObject<MobilityModel>()->GetPosition();
      wifiRx.Get(i)->GetObject<MobilityModel>()->SetPosition(Vector(posW.x + 10.0, posW.y, 0.0));
  }
  for (uint32_t i = 0; i < numNruPairs; i++) {
      Vector posN = nruTx.Get(i)->GetObject<MobilityModel>()->GetPosition();
      nruRx.Get(i)->GetObject<MobilityModel>()->SetPosition(Vector(posN.x + 10.0, posN.y, 0.0));
  }

  InternetStackHelper internet;
  internet.Install (allNodes);
  Ipv4AddressHelper ipv4;
  ipv4.SetBase ("10.1.0.0", "255.255.0.0");
  Ipv4InterfaceContainer interfaces = ipv4.Assign (allDevices);

  uint16_t port = 9;
  ApplicationContainer sinkApps;

  DataRate dr(dataRate);
  double lambda = dr.GetBitRate() / (1500.0 * 8.0);
  double meanInterval = 1.0 / lambda;

  for (uint32_t i = 0; i < numWifiPairs; i++) {
      PacketSinkHelper sink ("ns3::UdpSocketFactory", InetSocketAddress (Ipv4Address::GetAny (), port));
      sinkApps.Add (sink.Install (wifiRx.Get (i)));
  }
  for (uint32_t i = 0; i < numNruPairs; i++) {
      PacketSinkHelper sink ("ns3::UdpSocketFactory", InetSocketAddress (Ipv4Address::GetAny (), port));
      sinkApps.Add (sink.Install (nruRx.Get (i)));
  }
  sinkApps.Start (Seconds (0.0));
  sinkApps.Stop (Seconds (15.0));

  for (uint32_t i = 0; i < numWifiPairs; i++) {
      Ptr<Socket> socket = Socket::CreateSocket (wifiTx.Get (i), UdpSocketFactory::GetTypeId ());
      Address remote = InetSocketAddress (interfaces.GetAddress (numWifiPairs + i), port);
      socket->Connect (remote);
      Ptr<ExponentialRandomVariable> expRv = CreateObject<ExponentialRandomVariable> ();
      expRv->SetAttribute ("Mean", DoubleValue (meanInterval));
      Simulator::Schedule (Seconds (1.0 + (i * 0.1)), &GeneratePoissonTraffic, socket, 1500, expRv);
  }

  for (uint32_t i = 0; i < numNruPairs; i++) {
      Ptr<Socket> socket = Socket::CreateSocket (nruTx.Get (i), UdpSocketFactory::GetTypeId ());
      uint32_t rxIndex = 2 * numWifiPairs + numNruPairs + i;
      Address remote = InetSocketAddress (interfaces.GetAddress (rxIndex), port);
      socket->Connect (remote);
      Ptr<ExponentialRandomVariable> expRv = CreateObject<ExponentialRandomVariable> ();
      expRv->SetAttribute ("Mean", DoubleValue (meanInterval));
      Simulator::Schedule (Seconds (1.05 + (i * 0.1)), &GeneratePoissonTraffic, socket, 1500, expRv);
  }

  FlowMonitorHelper flowmon;
  Ptr<FlowMonitor> monitor = flowmon.InstallAll ();

  Simulator::Stop (Seconds (15.0));
  Simulator::Run ();

  monitor->CheckForLostPackets ();
  Ptr<Ipv4FlowClassifier> classifier = DynamicCast<Ipv4FlowClassifier> (flowmon.GetClassifier ());
  std::map<FlowId, FlowMonitor::FlowStats> stats = monitor->GetFlowStats ();

  double wifiTP = 0, nruTP = 0;
  double wifiDelaySum = 0.0, nruDelaySum = 0.0;
  uint32_t wifiC = 0, nruC = 0;
  uint32_t wifiTxTotal = 0, wifiRxTotal = 0;
  uint32_t nruTxTotal = 0, nruRxTotal = 0;

  uint32_t wifiTxStart = Ipv4Address("10.1.0.1").Get();
  uint32_t wifiTxEnd = wifiTxStart + numWifiPairs - 1;
  uint32_t nruTxStart = wifiTxStart + (2 * numWifiPairs);
  uint32_t nruTxEnd = nruTxStart + numNruPairs - 1;

  for (auto const& [id, stat] : stats) {
      Ipv4FlowClassifier::FiveTuple t = classifier->FindFlow (id);
      if (t.sourceAddress.IsSubnetDirectedBroadcast(Ipv4Mask("255.255.0.0"))) continue;

      uint32_t src = t.sourceAddress.Get();
      double tp = 0.0;
      if (stat.rxPackets > 0) {
          tp = stat.rxBytes * 8.0 / (stat.timeLastRxPacket.GetSeconds() - stat.timeFirstTxPacket.GetSeconds()) / 1000000.0;
      }

      if (src >= wifiTxStart && src <= wifiTxEnd) {
          wifiTxTotal += stat.txPackets;
          wifiRxTotal += stat.rxPackets;
          if (stat.rxPackets > 0) {
              wifiTP += tp;
              wifiC++;
              wifiDelaySum += stat.delaySum.GetSeconds();
          }
      } else if (src >= nruTxStart && src <= nruTxEnd) {
          nruTxTotal += stat.txPackets;
          nruRxTotal += stat.rxPackets;
          if (stat.rxPackets > 0) {
              nruTP += tp;
              nruC++;
              nruDelaySum += stat.delaySum.GetSeconds();
          }
      }
  }

  double avgWifiDelayMs = (wifiRxTotal > 0) ? (wifiDelaySum / wifiRxTotal) * 1000.0 : 0.0;
  double avgNruDelayMs  = (nruRxTotal > 0) ? (nruDelaySum / nruRxTotal) * 1000.0 : 0.0;

  std::cout << "\n--- Aggregated Grid Results (True Poisson + PPP) ---" << std::endl;
  std::cout << "[Diagnostics] WiFi Tx: " << wifiTxTotal << " | Rx: " << wifiRxTotal << std::endl;
  std::cout << "[Diagnostics] NR-U Tx: " << nruTxTotal << " | Rx: " << nruRxTotal << std::endl;

  std::cout << "Avg WiFi Throughput (per AP):   " << (wifiC > 0 ? wifiTP / wifiC : 0) << " Mbps" << std::endl;
  std::cout << "Avg NR-U Throughput (per gNB):  " << (nruC > 0 ? nruTP / nruC : 0) << " Mbps" << std::endl;

  std::cout << "Avg WiFi Delay: " << avgWifiDelayMs << " ms" << std::endl;
  std::cout << "Avg NR-U Delay: " << avgNruDelayMs << " ms" << std::endl;

  Simulator::Destroy ();
  return 0;
}
