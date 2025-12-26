import { useAuth } from "@/hooks/use-auth";
import { useWorkLogs, useUpdateWorkLog, useDeleteWorkLog } from "@/hooks/use-work-logs";
import { useAbsences } from "@/hooks/use-absences";
import Layout from "@/components/layout";
import { format, startOfMonth, endOfMonth } from "date-fns";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Pencil, Trash2, Check, X, CalendarClock, Filter } from "lucide-react";
import { useState } from "react";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { cn } from "@/lib/utils";

export default function EmployeeWorkHistory() {
  const { user } = useAuth();
  const [editingId, setEditingId] = useState<number | null>(null);
  const [editData, setEditData] = useState({ startTime: "", endTime: "" });
  const [filterType, setFilterType] = useState<"all" | "work" | "absence">("all");
  const [filterStartDate, setFilterStartDate] = useState("");
  const [filterEndDate, setFilterEndDate] = useState("");
  
  const today = new Date();
  const monthStart = format(startOfMonth(today), 'yyyy-MM-dd');
  const monthEnd = format(endOfMonth(today), 'yyyy-MM-dd');

  const { data: logs } = useWorkLogs({ 
    userId: user?.id, 
    startDate: filterStartDate || monthStart, 
    endDate: filterEndDate || monthEnd 
  });

  // Filter out absences from work logs and only show work logs and absence work logs
  const filteredLogs = logs?.filter(log => log.type !== 'absence') || [];
  
  // Apply type filter
  const filteredByType = filterType === "all" ? filteredLogs : filteredLogs.filter(log => log.type === filterType);

  const { data: absences } = useAbsences({ 
    userId: user?.id 
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

  // Calculate total hours for filtered data
  const totalHours = filteredByType.reduce((sum, log) => sum + log.totalHours, 0);
  const totalHoursFormatted = `${Math.floor(totalHours / 60)}h ${totalHours % 60}m`;

  // Combine only work logs for display (no absence records)
  const allEvents = filteredByType.map(l => ({ ...l, eventType: 'log' }))
    .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

  return (
    <Layout>
      <div className="space-y-8">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Mis Horas</h1>
          <p className="text-muted-foreground">Histórico detallado y edición de registros.</p>
        </div>

        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle>Todos los Registros</CardTitle>
              <div className="text-right">
                <div className="text-sm font-medium">Total de Horas</div>
                <div className="text-lg font-bold text-emerald-600">{totalHoursFormatted}</div>
              </div>
            </div>
            <div className="flex flex-wrap gap-4 pt-2">
              <div className="space-y-2">
                <Label className="text-xs">Tipo</Label>
                <Select value={filterType} onValueChange={(value: "all" | "work" | "absence") => setFilterType(value)}>
                  <SelectTrigger className="w-32">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">Todos</SelectItem>
                    <SelectItem value="work">Trabajo</SelectItem>
                    <SelectItem value="absence">Ausencia</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label className="text-xs">Desde</Label>
                <Input 
                  type="date" 
                  value={filterStartDate} 
                  onChange={e => setFilterStartDate(e.target.value)}
                  className="w-40"
                />
              </div>
              <div className="space-y-2">
                <Label className="text-xs">Hasta</Label>
                <Input 
                  type="date" 
                  value={filterEndDate} 
                  onChange={e => setFilterEndDate(e.target.value)}
                  className="w-40"
                />
              </div>
            </div>
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
                      <th className="p-4">Acciones</th>
                    </tr>
                  </thead>
                  <tbody>
                    {allEvents.length > 0 ? (
                      allEvents.map((event: any) => (
                        <tr key={event.id} className="border-b last:border-0 hover:bg-muted/20 transition-colors">
                          <td className="p-4">{format(new Date(event.date), 'dd/MM/yyyy')}</td>
                          <td className="p-4">
                            {editingId === event.id ? (
                              <Input 
                                type="time" 
                                value={editData.startTime} 
                                className="h-8 w-24"
                                onChange={e => setEditData({...editData, startTime: e.target.value})} 
                              />
                            ) : event.startTime}
                          </td>
                          <td className="p-4">
                            {editingId === event.id ? (
                              <Input 
                                type="time" 
                                value={editData.endTime} 
                                className="h-8 w-24"
                                onChange={e => setEditData({...editData, endTime: e.target.value})} 
                              />
                            ) : event.endTime}
                          </td>
                          <td className="p-4 font-medium">
                            {Math.floor(event.totalHours / 60)}h {event.totalHours % 60}m
                          </td>
                          <td className="p-4 flex gap-1">
                            {editingId === event.id ? (
                              <>
                                <Button size="icon" variant="ghost" className="h-8 w-8 text-emerald-600" onClick={() => handleSave(event.id)}>
                                  <Check className="h-4 w-4" />
                                </Button>
                                <Button size="icon" variant="ghost" className="h-8 w-8 text-muted-foreground" onClick={() => setEditingId(null)}>
                                  <X className="h-4 w-4" />
                                </Button>
                              </>
                            ) : (
                              <>
                                <Button size="icon" variant="ghost" className="h-8 w-8" onClick={() => handleEdit(event)}>
                                  <Pencil className="h-4 w-4" />
                                </Button>
                                <Button size="icon" variant="ghost" className="h-8 w-8 text-red-600" onClick={() => deleteLog.mutate(event.id)}>
                                  <Trash2 className="h-4 w-4" />
                                </Button>
                              </>
                            )}
                          </td>
                        </tr>
                      ))
                    ) : (
                      <tr>
                        <td colSpan={5} className="p-8 text-center text-muted-foreground">
                          No hay registros disponibles
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
