import { useAuth } from "@/hooks/use-auth";
import { useWorkLogs, useUpdateWorkLog, useDeleteWorkLog } from "@/hooks/use-work-logs";
import Layout from "@/components/layout";
import { format, startOfMonth, endOfMonth } from "date-fns";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Pencil, Trash2, Check, X } from "lucide-react";
import { useState } from "react";
import { Input } from "@/components/ui/input";
import { cn } from "@/lib/utils";

export default function EmployeeWorkHistory() {
  const { user } = useAuth();
  const [editingId, setEditingId] = useState<number | null>(null);
  const [editData, setEditData] = useState({ startTime: "", endTime: "" });
  
  const today = new Date();
  const monthStart = format(startOfMonth(today), 'yyyy-MM-dd');
  const monthEnd = format(endOfMonth(today), 'yyyy-MM-dd');

  const { data: logs } = useWorkLogs({ 
    userId: user?.id, 
    startDate: monthStart, 
    endDate: monthEnd 
  });

  const updateLog = useUpdateWorkLog();
  const deleteLog = useDeleteWorkLog();

  const handleEdit = (log: any) => {
    setEditingId(log.id);
    setEditData({ startTime: log.startTime, endTime: log.endTime });
  };

  const handleSave = async (id: number) => {
    const [sH, sM] = editData.startTime.split(':').map(Number);
    const [eH, eM] = editData.endTime.split(':').map(Number);
    const totalHours = (eH * 60 + eM) - (sH * 60 + sM);

    await updateLog.mutateAsync({
      id,
      startTime: editData.startTime,
      endTime: editData.endTime,
      totalHours: totalHours > 0 ? totalHours : 0
    });
    setEditingId(null);
  };

  return (
    <Layout>
      <div className="space-y-8">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Mis Horas</h1>
          <p className="text-muted-foreground">Histórico detallado y edición de registros.</p>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Registros del Mes</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="rounded-md border overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead className="bg-muted/50 border-b">
                    <tr className="text-left">
                      <th className="p-4">Fecha</th>
                      <th className="p-4">Entrada</th>
                      <th className="p-4">Salida</th>
                      <th className="p-4">Duración</th>
                      <th className="p-4">Tipo</th>
                      <th className="p-4">Acciones</th>
                    </tr>
                  </thead>
                  <tbody>
                    {logs && logs.length > 0 ? (
                      logs.map((log) => (
                        <tr key={log.id} className="border-b last:border-0 hover:bg-muted/20 transition-colors">
                          <td className="p-4">{format(new Date(log.date), 'dd/MM/yyyy')}</td>
                          <td className="p-4">
                            {editingId === log.id ? (
                              <Input 
                                type="time" 
                                value={editData.startTime} 
                                className="h-8 w-24"
                                onChange={e => setEditData({...editData, startTime: e.target.value})} 
                              />
                            ) : log.startTime}
                          </td>
                          <td className="p-4">
                            {editingId === log.id ? (
                              <Input 
                                type="time" 
                                value={editData.endTime} 
                                className="h-8 w-24"
                                onChange={e => setEditData({...editData, endTime: e.target.value})} 
                              />
                            ) : log.endTime}
                          </td>
                          <td className="p-4 font-medium">{Math.floor(log.totalHours / 60)}h {log.totalHours % 60}m</td>
                          <td className="p-4">
                            <span className={cn(
                              "px-2 py-0.5 rounded-full text-[10px] font-medium border",
                              log.type === 'work' ? "bg-emerald-50 text-emerald-700 border-emerald-100" : "bg-blue-50 text-blue-700 border-blue-100"
                            )}>
                              {log.type === 'work' ? 'Trabajo' : 'Ausencia'}
                            </span>
                          </td>
                          <td className="p-4 flex gap-1">
                            {editingId === log.id ? (
                              <>
                                <Button size="icon" variant="ghost" className="h-8 w-8 text-emerald-600" onClick={() => handleSave(log.id)}>
                                  <Check className="h-4 w-4" />
                                </Button>
                                <Button size="icon" variant="ghost" className="h-8 w-8 text-muted-foreground" onClick={() => setEditingId(null)}>
                                  <X className="h-4 w-4" />
                                </Button>
                              </>
                            ) : (
                              <>
                                <Button size="icon" variant="ghost" className="h-8 w-8" onClick={() => handleEdit(log)}>
                                  <Pencil className="h-4 w-4" />
                                </Button>
                                <Button size="icon" variant="ghost" className="h-8 w-8 text-red-600" onClick={() => deleteLog.mutate(log.id)}>
                                  <Trash2 className="h-4 w-4" />
                                </Button>
                              </>
                            )}
                          </td>
                        </tr>
                      ))
                    ) : (
                      <tr>
                        <td colSpan={6} className="p-8 text-center text-muted-foreground">
                          No hay registros para este mes
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </Layout>
  );
}
