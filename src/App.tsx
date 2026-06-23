import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { AppProvider } from './context/AppContext';
import Layout from './components/Layout/Layout';
import Dashboard from './pages/Dashboard';
import Projets from './pages/Projets';
import ProjetDetail from './pages/ProjetDetail';
import Membres from './pages/Membres';
import Cotisations from './pages/Cotisations';
import Rappels from './pages/Rappels';
import Rapports from './pages/Rapports';

export default function App() {
  return (
    <AppProvider>
      <BrowserRouter>
        <Layout>
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/projets" element={<Projets />} />
            <Route path="/projets/:id" element={<ProjetDetail />} />
            <Route path="/membres" element={<Membres />} />
            <Route path="/cotisations" element={<Cotisations />} />
            <Route path="/rappels" element={<Rappels />} />
            <Route path="/rapports" element={<Rapports />} />
          </Routes>
        </Layout>
      </BrowserRouter>
    </AppProvider>
  );
}
