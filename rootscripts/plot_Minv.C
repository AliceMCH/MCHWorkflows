TH1F* GetTH1(TFile* f, TString histname)
{
  //TString histname = TString::Format("ST%d/DE%d/Occupancy_B_XY_%d", station, de, de);
  TKey *key = f->GetKey(histname);
  std::cout << "histname: " << histname << "  key: " <<key << std::endl;
  if (!key) return NULL;
  return (TH1F*)key->ReadObjectAny(TH1F::Class());
}

TH2F* GetTH2(TFile* f, TString histname)
{
  //TString histname = TString::Format("ST%d/DE%d/Occupancy_B_XY_%d", station, de, de);
  TKey *key = f->GetKey(histname);
  std::cout << "histname: " << histname << "  key: " <<key << std::endl;
  if (!key) return NULL;
  return (TH2F*)key->ReadObjectAny(TH2F::Class());
}

void plot_Minv()
{
  //gStyle->SetOptStat(0);
  gStyle->SetOptFit(1111);
  gStyle->SetPalette(57, 0);
  gStyle->SetNumberContours(40);
  int cW = 1800;
  int cH = 1200;
  TCanvas c("c","c",cW,cH);
  //gPad->SetLogy(kTRUE);
    
  for (int fi = 0; fi < 2; fi++) {
    TFile* fmchmid = nullptr;
    fmchmid = new TFile("Outputs/run00523252/qc-mftmchmid-tracks.root");

    std::string folderName;
    if (fi == 0) folderName = "MCH";
    else folderName = "MCH-MID";

    TH1F* hMinv = GetTH1(fmchmid, TString::Format("%s/Minv", folderName.c_str()));
    if (!hMinv) {
      break;
    }
    hMinv->SetStats(1111);
    TH1F* hMinvBgd = GetTH1(fmchmid, TString::Format("%s/MinvBgd", folderName.c_str()));
    hMinv->Rebin(2);
    hMinvBgd->Rebin(2);
    TH1F* hMinvSig = (TH1F*)hMinv->Clone();
    
    int x1 = hMinv->GetXaxis()->FindBin(3.5);
    int x2 = hMinv->GetXaxis()->FindBin(5);
    
    Double_t sigInt = hMinv->Integral(x1, x2);
    Double_t bgdInt = hMinvBgd->Integral(x1, x2);
    
    std::cout << "scale: " << (sigInt / bgdInt) << std::endl;
    hMinvBgd->Scale(sigInt / bgdInt);
    //hMinvSig->Add(hMinv, 1);
    hMinvSig->Add(hMinvBgd, -1);
    
    hMinv->GetXaxis()->SetRangeUser(1, 5);
    hMinv->SetLineColor(kBlack);
    hMinvBgd->SetLineColor(kBlue);
    hMinv->Draw();
    hMinvBgd->Draw("same");
        
    if (fi == 0) {
      c.SaveAs("Minv.pdf(");
    } else {
      c.SaveAs("Minv.pdf");
    }

    hMinvSig->SetLineColor(kRed);
    hMinvSig->SetMinimum(0);
    hMinvSig->GetXaxis()->SetRangeUser(1, 5);
    hMinvSig->Draw();
    TF1 fitFunc("fitFunc", "gausn(0) + expo(3)", 2, 4);
    fitFunc.SetParName(1, "M_{#mu^{+}#mu^{-}}");
    fitFunc.SetParName(2, "#sigma_{#mu^{+}#mu^{-}}");
    fitFunc.FixParameter(1, 3.1);
    fitFunc.SetParameter(2, 0.1);
    fitFunc.SetParLimits(0, 0, 1000000);
    fitFunc.SetParLimits(2, 0.01, 1);
    hMinvSig->Fit("fitFunc","RN");
    fitFunc.ReleaseParameter(1);
    hMinvSig->Fit("fitFunc","R");
    c.SaveAs("Minv.pdf");
    hMinvSig->GetXaxis()->SetRangeUser(2, 4);
    hMinvSig->Draw();
    c.SaveAs("Minv.pdf");

    std::cout << "N(J/Psi) = " << fitFunc.GetParameter(0) / hMinvSig->GetBinWidth(1) 
	      << " +/- " << fitFunc.GetParError(0) / hMinvSig->GetBinWidth(1) << std::endl;
  }

  c.Clear();
  c.SaveAs("Minv.pdf)");
}
