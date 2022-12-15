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
  TFile* fmchmid = new TFile("qc-mchmid-tracks.root");

  //gStyle->SetOptStat(0);
  gStyle->SetOptFit(1111);
  gStyle->SetPalette(57, 0);
  gStyle->SetNumberContours(40);
  int cW = 1800;
  int cH = 1200;
  TCanvas c("c","c",cW,cH);
  //gPad->SetLogy(kTRUE);

  TH1F* hMinv = GetTH1(fmchmid, "MCH-MID/Minv");
  hMinv->SetStats(1111);
  TH1F* hMinvBgd = GetTH1(fmchmid, "MCH-MID/MinvBgd");
  hMinv->Rebin(2);
  hMinvBgd->Rebin(2);
  TH1F* hMinvSig = (TH1F*)hMinv->Clone();

  int x1 = hMinv->GetXaxis()->FindBin(4);
  int x2 = hMinv->GetXaxis()->FindBin(5);

  Double_t sigInt = hMinv->Integral(x1, x2);
  Double_t bgdInt = hMinvBgd->Integral(x1, x2);

  std::cout << "scale: " << (sigInt / bgdInt) << std::endl;
  hMinvBgd->Scale(sigInt / bgdInt);
  //hMinvSig->Add(hMinv, 1);
  hMinvSig->Add(hMinvBgd, -1);

  hMinv->SetLineColor(kBlack);
  hMinvSig->SetLineColor(kRed);
  hMinvBgd->SetLineColor(kBlue);
  hMinvSig->GetXaxis()->SetRangeUser(1, 5);
  hMinvSig->SetMinimum(0);
  hMinvSig->Draw();
  hMinvBgd->Draw("same");
  hMinv->Draw("same");

  TF1 fitFunc("fitFunc", "gausn(0) + expo(3)", 2, 4);
  fitFunc.SetParName(1, "M_{#mu^{+}#mu^{-}}");
  fitFunc.SetParName(2, "#sigma_{#mu^{+}#mu^{-}}");
  fitFunc.FixParameter(1, 3);
  fitFunc.SetParameter(2, 0.1);
  fitFunc.SetParLimits(2, 0, 1);
  hMinvSig->Fit("fitFunc","RN");
  fitFunc.ReleaseParameter(1);
  hMinvSig->Fit("fitFunc","R");

  c.SaveAs("Minv.pdf");
}
