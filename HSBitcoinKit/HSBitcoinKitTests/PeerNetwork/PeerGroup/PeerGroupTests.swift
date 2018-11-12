import XCTest
import Cuckoo
import RealmSwift
import RxSwift
import Alamofire
import HSHDWalletKit
@testable import HSBitcoinKit

class PeerGroupTests: XCTestCase {

    internal var mockFactory: MockIFactory!
    internal var mockNetwork: MockINetwork!
    internal var mockBestBlockHeightListener: MockBestBlockHeightListener!
    internal var mockReachabilityManager: MockIReachabilityManager!
    internal var mockPeerHostManager: MockIPeerHostManager!
    internal var mockBloomFilterManager: MockIBloomFilterManager!
    internal var mockPeers: MockIPeers!
    internal var mockBlockSyncer: MockIBlockSyncer!
    internal var mockTransactionSyncer: MockITransactionSyncer!

    internal var peerGroup: PeerGroup!

    internal var peersCount = 3
    internal var peers: [String: MockIPeer]!
    internal var subject: PublishSubject<NetworkReachabilityManager.NetworkReachabilityStatus>!

    override func setUp() {
        super.setUp()

        mockFactory = MockIFactory()
        mockNetwork = MockINetwork()
        mockBestBlockHeightListener = MockBestBlockHeightListener()
        mockReachabilityManager = MockIReachabilityManager()
        mockPeerHostManager = MockIPeerHostManager()
        mockBloomFilterManager = MockIBloomFilterManager()
        mockPeers = MockIPeers()
        mockBlockSyncer = MockIBlockSyncer()
        mockTransactionSyncer = MockITransactionSyncer()
        peers = [String: MockIPeer]()
        subject = PublishSubject<NetworkReachabilityManager.NetworkReachabilityStatus>()

        for host in 0..<4 {
            let hostString = String(host)
            let mockPeer = MockIPeer()
            peers[hostString] = mockPeer

            stub(mockFactory) { mock in
                when(mock.peer(withHost: equal(to: hostString), network: any())).thenReturn(mockPeer)
            }
        }
        resetStubsAndInvocationsOfPeers()

        stub(mockBestBlockHeightListener) { mock in
            when(mock.bestBlockHeightReceived(height: any())).thenDoNothing()
        }
        stub(mockReachabilityManager) { mock in
            when(mock.subject.get).thenReturn(subject)
            when(mock.reachable()).thenReturn(true)
        }
        stub(mockPeerHostManager) { mock in
            when(mock.delegate.set(any())).thenDoNothing()
            when(mock.peerHost.get).thenReturn("0").thenReturn("1").thenReturn("2").thenReturn("3")
            when(mock.hostDisconnected(host: any(), withError: any(), networkReachable: any())).thenDoNothing()
        }
        stub(mockBloomFilterManager) { mock in
            when(mock.delegate.set(any())).thenDoNothing()
            when(mock.bloomFilter.get).thenReturn(nil)
        }
        stub(mockPeers) { mock in
            when(mock.syncPeer.get).thenReturn(nil)
            when(mock.add(peer: any())).thenDoNothing()
            when(mock.peerConnected(peer: any())).thenDoNothing()
            when(mock.peerDisconnected(peer: any())).thenDoNothing()
            when(mock.disconnectAll()).thenDoNothing()
            when(mock.totalPeersCount()).thenReturn(0)
            when(mock.someReadyPeers()).thenReturn([IPeer]())
            when(mock.connected()).thenReturn([IPeer]())
            when(mock.nonSyncedPeer()).thenReturn(nil)
            when(mock.syncPeerIs(peer: any())).thenReturn(false)
        }
        stub(mockBlockSyncer) { mock in
            when(mock.localBestBlockHeight.get).thenReturn(0)
            when(mock.prepareForDownload()).thenDoNothing()
            when(mock.downloadStarted()).thenDoNothing()
            when(mock.downloadCompleted()).thenDoNothing()
        }
        stub(mockTransactionSyncer) { mock in
            when(mock.pendingTransactions()).thenReturn([Transaction]())
            when(mock.handle(transactions: any())).thenDoNothing()
            when(mock.handle(sentTransaction: any())).thenDoNothing()
            when(mock.shouldRequestTransaction(hash: any())).thenReturn(false)
        }

        peerGroup = PeerGroup(
                factory: mockFactory, network: mockNetwork, listener: mockBestBlockHeightListener, reachabilityManager: mockReachabilityManager, peerHostManager: mockPeerHostManager, bloomFilterManager: mockBloomFilterManager,
                peerCount: peersCount, peers: mockPeers,
                peersQueue: DispatchQueue.main, inventoryQueue: DispatchQueue.main
        )
        peerGroup.blockSyncer = mockBlockSyncer
        peerGroup.transactionSyncer = mockTransactionSyncer
    }

    override func tearDown() {
        mockFactory = nil
        mockNetwork = nil
        mockBestBlockHeightListener = nil
        mockReachabilityManager = nil
        mockPeerHostManager = nil
        mockBloomFilterManager = nil
        mockBlockSyncer = nil
        mockTransactionSyncer = nil

        peerGroup = nil
        peers = nil
        subject = nil

        super.tearDown()
    }

    internal func verifyConnectTriggeredOnlyForPeers(withHosts hosts: [String]) {
        for (host, peer) in peers {
            if hosts.contains(where: { expectedHost in return expectedHost == host }) {
                verify(peer).connect()
            } else {
                verify(peer, never()).connect()
            }
        }
    }

    // Other Helper Methods

    internal func resetStubsAndInvocationsOfPeers() {
        for (host, mockPeer) in peers {
            reset(mockPeer)

            stub(mockPeer) { mock in
                when(mock.announcedLastBlockHeight.get).thenReturn(0)
                when(mock.localBestBlockHeight.get).thenReturn(0)
                when(mock.localBestBlockHeight.set(any())).thenDoNothing()
                when(mock.logName.get).thenReturn(host)
                when(mock.ready.get).thenReturn(false)
                when(mock.synced.get).thenReturn(false)
                when(mock.blockHashesSynced.get).thenReturn(false)
                when(mock.delegate.set(any())).thenDoNothing()
                when(mock.host.get).thenReturn(host)

                when(mock.connect()).thenDoNothing()
                when(mock.disconnect(error: any())).thenDoNothing()
                when(mock.add(task: any())).thenDoNothing()
                when(mock.isRequestingInventory(hash: any())).thenReturn(false)
                when(mock.filterLoad(bloomFilter: any())).thenDoNothing()

                when(mock.equalTo(equal(to: mockPeer, equalWhen: { $0?.host == $1?.host }))).thenReturn(true)
                when(mock.equalTo(equal(to: mockPeer, equalWhen: { $0?.host != $1?.host }))).thenReturn(false)
            }
        }
    }

}
