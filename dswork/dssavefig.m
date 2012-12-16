% Author: Carl Doersch (cdoersch at cs dot cmu dot edu)
function dssavefig(fig,pdfname,jpgname)
              figsettings=get(fig,'UserData');
              if(isfield(figsettings,'jpgsize'))
                scrposjpg=[0,0,figsettings.jpgsize];
                scrpospdf=[0,0,figsettings.pdfsize];
              elseif(isfield(figsettings,'bothsize'))
                scrposjpg=[0,0,figsettings.bothsize];
                scrpospdf=[0,0,figsettings.bothsize];
              else
                scrposjpg=[0,0,800,600];
                scrpospdf=[0,0,800,600];
              end
              oldscreenunits = get(fig,'Units');
              oldpaperunits = get(fig,'PaperUnits');
              oldpaperpos = get(fig,'PaperPosition');
              set(fig,'Units','pixels');
              %scrpos = get(fig,'Position')
              newpos = scrpospdf/100;
              papersize=scrpospdf(3:end)/100;
              set(fig,'PaperSize',papersize,'PaperUnits','inches',...
              'PaperPosition',newpos)
              %print('-djpeg', filename, '-r100');
              %export_fig(filenm2,f{i});
              drawnow
              print(fig,'-dpdf',pdfname,'-r100');

              %scrpos = get(fig,'Position')
              newpos = scrposjpg/100;
              set(fig,'PaperUnits','inches',...
              'PaperPosition',newpos)

              print(fig,'-djpeg',jpgname,'-r100');
              set(fig,'Units',oldscreenunits,...
              'PaperUnits',oldpaperunits,...
              'PaperPosition',oldpaperpos);
end
