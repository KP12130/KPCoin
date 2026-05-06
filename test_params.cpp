#include <iostream>
#include <kernel/chainparams.h>
#include <util/chaintype.h>
#include <memory>

int main() {
    std::cout << "Testing KPCoin Params Initialization..." << std::endl;
    try {
        std::unique_ptr<const CChainParams> params = CChainParams::Main();
        if (params) {
            std::cout << "SUCCESS! Genesis Hash: " << params->GetConsensus().hashGenesisBlock.ToString() << std::endl;
        } else {
            std::cout << "FAILED: params is null" << std::endl;
        }
    } catch (const std::exception& e) {
        std::cerr << "FAILED with exception: " << e.what() << std::endl;
        return 1;
    } catch (...) {
        std::cerr << "FAILED with unknown error!" << std::endl;
        return 1;
    }
    return 0;
}
